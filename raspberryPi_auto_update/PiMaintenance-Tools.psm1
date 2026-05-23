<#
RASPBERRY PI TOOLS

Public API:
- Invoke-MaintenanceCommand  (for maintenance checks: uptime, temp, disk, Pi-hole status)
- Invoke-UpdateCommand       (for OS + Pi-hole updates)
- ConvertFrom-AptSummary
- Write-LogSummary
#>

# -------------------------
# LAYER 1: UI HELPERS (PUBLIC)
# -------------------------


function Show-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "→ $Message" -ForegroundColor Cyan
}

function Show-Result {
    param(
        [string]$TaskName,
        [bool]$Success
    )

    if ($Success) {
        Write-Host "✓ $TaskName successful" -ForegroundColor Green
    }
    else {
        Write-Host "✗ $TaskName failed" -ForegroundColor Red
    }
}

# -------------------------
# LAYER 2: RAW SSH EXECUTION (INTERNAL)
# -------------------------

function Invoke-RawSsh {
    <#
    .SYNOPSIS
        Runs an SSH command on the Raspberry Pi and returns raw output + success flag.
    .PARAMETER Command
        The command to run on the Raspberry Pi (e.g., "hostname").
    .PARAMETER PiHost
        The SSH host string (e.g., "****@***").
    .OUTPUTS
        PSCustomObject with Success (bool) and RawOutput (string).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,

        [Parameter(Mandatory=$true)]
        [string]$PiHost,

        [Parameter()]
        [int]$RetryCount = 0,

        [Parameter()]
        [int]$RetryDelaySeconds = 0,

        [Parameter()]
        [switch]$DryRun
    )

    # DRY RUN MODE — no SSH executed
    if ($DryRun) {
        return [PSCustomObject]@{
            Success       = $true
            RawOutput     = "[DRY RUN] Command skipped: $Command"
            ErrorCategory = "None"
        }
    } 

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    $attempt = 0
    
    while ($attempt -le $RetryCount) {
   
        $raw = ssh "$PiHost" "$Command" 2>&1
        $success = $LASTEXITCODE -eq 0
        $text = ($raw | Out-String)

        # Error categorisation
        $category = "None"
        if (-not $success) {
            if ($text -match "Permission denied") { $category = "AuthenticationError" }
            elseif ($text -match "Could not resolve hostname") { $category = "DnsError" }
            elseif ($text -match "Connection timed out") { $category = "TimeoutError" }
            elseif ($text -match "Connection refused") { $category = "ConnectionError" }
            else { $category = "UnknownError" }
        }

        # SUCCESS — return immediately
        if ($success) {        
            return [PSCustomObject]@{
                Success   = $true
                RawOutput = $text
                ErrorCategory = "None"        
            }
        }

        # FAILURE — check if we should retry
        if ($attempt -lt $RetryCount) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }

        $attempt++
    }

    # FINAL FAILURE — return last error
    return [PSCustomObject]@{
        Success       = $false
        RawOutput     = $text
        ErrorCategory = $category
    }
}


# -------------------------
# LAYER 3: NORMALISATION HELPERS (INTERNAL)
# -------------------------

function Normalize-SingleLine {
    <#
    .SYNOPSIS
        Normalises raw SSH output into a single trimmed string.
    .PARAMETER RawOutput
        Raw string from Invoke-RawSsh.
    #>
    param([string]$RawOutput)
    if ([string]::IsNullOrWhiteSpace($RawOutput)) { return "" }
    return $RawOutput.Trim()
}

function Normalize-MultiLine {
    <#
    .SYNOPSIS
        Normalises raw SSH output into an array of lines.
    .PARAMETER RawOutput
        Raw string from Invoke-RawSsh.
    #>
    param([string]$RawOutput)
    if ([string]::IsNullOrWhiteSpace($RawOutput)) { return @() }

    $text = $RawOutput.TrimEnd()
    $lines = $text -split "`n"

    # Trim each line AND remove lines that are only whitespace
    $clean = $lines |
        ForEach-Object { $_.TrimEnd() } |
        Where-Object { $_ -ne "" }

    return $clean
}

# -------------------------
# LAYER 4: PUBLIC WRAPPERS
# -------------------------

function Invoke-MaintenanceCommand {
    <#
    .SYNOPSIS
        Runs a maintenance SSH command, logs success/failure and logs output in a consistent format.
    .PARAMETER TaskName
        Descriptive name for the task (e.g., "Check disk space").
    .PARAMETER OutputLabel
        Label for the output section (e.g., "Disk space"). Defaults to TaskName.
    .PARAMETER Command
        SSH command to run.
    .PARAMETER PiHost
        SSH host string.
    .PARAMETER LogPath
        Path to the log file.
    .PARAMETER MultiLine
        If set, output is treated as multi-line; otherwise single-line.
    .OUTPUTS
        PSCustomObject with Success and Output (string[]).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,

        [Parameter()]
        [string]$OutputLabel,

        [Parameter(Mandatory=$true)]
        [string]$Command,

        [Parameter(Mandatory=$true)]
        [string]$PiHost,

        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [Parameter()]
        [int]$RetryCount = 0,

        [Parameter()]
        [int]$RetryDelaySeconds = 0,

        [Parameter()]
        [switch]$DryRun,

        [Parameter()]
        [switch]$NoOutput,

        [Parameter()]
        [switch]$MultiLine
    )
    Show-Step $TaskName

    $result = Invoke-RawSsh `
        -Command $Command `
        -PiHost $PiHost
        -RetryCount $RetryCount `
        -RetryDelaySeconds $RetryDelaySeconds `
        -DryRun:$DryRun
    
    if ($MultiLine) {
        $lines = Normalize-MultiLine -RawOutput $result.RawOutput
    }
    else {
        $single = Normalize-SingleLine -RawOutput $result.RawOutput
        $lines = @($single)
    }

    # Log success/failure
    if ($result.Success) {
        "{$TaskName}: successful" | Out-File $LogPath -Append
    }
    else {
        "{$TaskName}: failed" | Out-File $LogPath -Append
        "ERROR CATEGORY: $($result.ErrorCategory)" | Out-File $LogPath -Append
        if ($lines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($lines[0])) {
            "ERROR: $($lines[0])`n" | Out-File $LogPath -Append
        }
    }

    # Terminal output
    Show-Result $TaskName $result.Success

    # Log output
    if (-not $NoOutput) {
        $label = if ($OutputLabel) { $OutputLabel } else { $TaskName }

        if ($MultiLine) {
            "{$label}:" | Out-File $LogPath -Append
            $lines | ForEach-Object { "    $_" | Out-File $LogPath -Append }
            "" | Out-File $LogPath -Append
        }
        else {
            "{$label}: $($lines[0])`n" | Out-File $LogPath -Append
        }
    }

    return [PSCustomObject]@{
        Success = $result.Success
        Output  = $lines
        Error   = if ($result.Success) { $null } else { $lines[0] }
    }
}

function Invoke-UpdateCommand {
    <#
    .SYNOPSIS
        Runs an update-related SSH command (apt, Pi-hole), logs success/failure, optionally logs output.
    .PARAMETER TaskName
        Descriptive name for the task.
    .PARAMETER Command
        SSH command to run.
    .PARAMETER PiHost
        SSH host string.
    .PARAMETER LogPath
        Path to the log file.
    .PARAMETER LogOutput
        If set, logs the full output.
    .OUTPUTS
        PSCustomObject with Success and Output (string[]).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,

        [Parameter(Mandatory=$true)]
        [string]$Command,

        [Parameter(Mandatory=$true)]
        [string]$PiHost,

        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [Parameter()]
        [int]$RetryCount = 0,

        [Parameter()]
        [int]$RetryDelaySeconds = 0,
       
        [Parameter()]
        [switch]$DryRun,

        [Parameter()]
        [switch]$LogOutput        
    )
    Show-Step $TaskName

    $result = Invoke-RawSsh `
        -Command $Command `
        -PiHost $PiHost `
        -RetryCount $RetryCount `
        -RetryDelaySeconds $RetryDelaySeconds `
        -DryRun:$DryRun
    
    $lines  = Normalize-MultiLine -RawOutput $result.RawOutput

    if ($result.Success) {
        "{$TaskName}: successful" | Out-File $LogPath -Append
    }
    else {
        "{$TaskName}: failed" | Out-File $LogPath -Append
        "ERROR CATEGORY: $($result.ErrorCategory)" | Out-File $LogPath -Append
        if ($lines.Count -gt 0) {
            "ERROR: $($lines[0])`n" | Out-File $LogPath -Append
        }
    }

    Show-Result $TaskName $result.Success

    if ($result.Success -and $LogOutput) {
        "{$TaskName} output:" | Out-File $LogPath -Append
        $lines | ForEach-Object { "    $_" | Out-File $LogPath -Append }
        "" | Out-File $LogPath -Append
    }

    return [PSCustomObject]@{
        Success = $result.Success
        Output  = $lines
        Error   = if ($result.Success) { $null } else { $lines[0] }
    }
}

# -------------------------
# EXISTING FUNCTIONS (UNCHANGED)
# -------------------------

function ConvertFrom-AptSummary {
    <#
    .SYNOPSIS
        Generates a stable summary of upgradeable packages using
        `apt list --upgradeable` output.
    .PARAMETER Output
        Raw output from `apt list --upgradeable`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Output
    )

    $packages = $Output |
        Where-Object { $_ -match "/" -and $_ -notmatch "Listing..." } |
        ForEach-Object { ($_ -split " ")[0] }

    $count = $packages.Count

    return [PSCustomObject]@{
        "Upgrading" = @()
        "Not Upgrading" = $packages
        "Summary"       = @(
            "Upgrading: 0",
            "Installing: 0",
            "Removing: 0",
            "Not Upgrading: $count"
        )
        "Errors"        = @()
    }
}

function Write-LogSummary {
    <#
    .SYNOPSIS
        Writes a structured summary object to the log file in a readable format.
    .PARAMETER SummaryObject
        The summary object to be written to the log file.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [pscustomobject]$SummaryObject,

        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )

    foreach ($property in $SummaryObject.PSObject.Properties) {

        if ($property.Name -eq "Errors") { continue }

        $Label = $property.Name
        $Value = $property.Value

        if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
            "{$Label}:" | Out-File $LogPath -Append
            $Value | ForEach-Object { "    $_" | Out-File $LogPath -Append }
            continue
        }

        if ($null -ne $Value) {
            "{$Label}: $Value" | Out-File $LogPath -Append
        }
        else {
            "{$Label}: <no Value>" | Out-File $LogPath -Append
        }
    }

    if ($SummaryObject.Errors -and $SummaryObject.Errors.Count -gt 0) {
        "Summary extraction errors:" | Out-File $LogPath -Append
        foreach ($err in $SummaryObject.Errors) {
            "    $err" | Out-File $LogPath -Append
        }
    }
}

# -------------------------
# EXPORT PUBLIC API
# -------------------------

Export-ModuleMember -Function `
    Invoke-MaintenanceCommand, `
    Invoke-UpdateCommand, `
    ConvertFrom-AptSummary, `
    Write-LogSummary, `
    Show-Step, `
    Show-Result