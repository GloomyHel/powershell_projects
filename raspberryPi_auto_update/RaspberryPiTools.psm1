<#
RASPBERRY PI TOOLS

Public API:
- Invoke-MaintenanceCommand  (for maintenance checks: uptime, temp, disk, Pi-hole status)
- Invoke-UpdateCommand       (for OS + Pi-hole updates)
- ConvertFrom-AptSummary
- Write-LogSummary
#>

# -------------------------
# LAYER 1: RAW SSH EXECUTION (INTERNAL)
# -------------------------

function Invoke-RawSsh {
    <#
    .SYNOPSIS
        Runs an SSH command on the Raspberry Pi and returns raw output + success flag.
    .PARAMETER Command
        The command to run on the Raspberry Pi (e.g., "hostname").
    .PARAMETER PiHost
        The SSH host string (e.g., "thewizard@blockmagic").
    .OUTPUTS
        PSCustomObject with Success (bool) and RawOutput (string).
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,

        [Parameter(Mandatory=$true)]
        [string]$PiHost
    )

    $raw = ssh "$PiHost" "$Command" 2>&1
    $success = $LASTEXITCODE -eq 0
    $text = ($raw | Out-String)

    return [PSCustomObject]@{
        Success   = $success
        RawOutput = $text
    }
}

# -------------------------
# LAYER 2: NORMALISATION HELPERS (INTERNAL)
# -------------------------

function Normalize-SingleLine {
    <#
    .SYNOPSIS
        Normalises raw SSH output into a single trimmed string.
    .PARAMETER RawOutput
        Raw string from Invoke-RawSsh.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$RawOutput
    )
    if ([string]::IsNullOrWhiteSpace($RawOutput)) {
        return ""
    }
    return $RawOutput.Trim()
}

function Normalize-MultiLine {
    <#
    .SYNOPSIS
        Normalises raw SSH output into an array of lines.
    .PARAMETER RawOutput
        Raw string from Invoke-RawSsh.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$RawOutput
    )

    $text = $RawOutput.TrimEnd()
    $lines = $text -split "`n"

    # Trim each line AND remove lines that are only whitespace
    $clean = $lines |
        ForEach-Object { $_.TrimEnd() } |
        Where-Object { $_ -ne "" }

    return $clean
}

# -------------------------
# LAYER 3: PUBLIC WRAPPERS
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
        [switch]$NoOutput,

        [switch]$MultiLine
    )

    $result = Invoke-RawSsh -Command $Command -PiHost $PiHost

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
        if ($lines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($lines[0])) {
            "ERROR: $($lines[0])`n" | Out-File $LogPath -Append
        }
        return [PSCustomObject]@{
            Success = $false
            Output  = $lines
        }
    }

    # Log output
    $label = if ($OutputLabel) { $OutputLabel } else { $TaskName }

    if ($MultiLine) {
        "{$label}:" | Out-File $LogPath -Append
        $lines | ForEach-Object { "    $_" | Out-File $LogPath -Append }
        "" | Out-File $LogPath -Append
    }
    else {
        "{$label}: $($lines[0])`n" | Out-File $LogPath -Append
    }

    return [PSCustomObject]@{
        Success = $true
        Output  = $lines
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

        [switch]$LogOutput
    )

    $result = Invoke-RawSsh -Command $Command -PiHost $PiHost
    $lines  = Normalize-MultiLine -RawOutput $result.RawOutput

    if ($result.Success) {
        "{$TaskName}: successful" | Out-File $LogPath -Append
    }
    else {
        "{$TaskName}: failed" | Out-File $LogPath -Append
        if ($lines.Count -gt 0) {
            "ERROR: $($lines[0])`n" | Out-File $LogPath -Append
        }
    }

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
Export-ModuleMember -Function Invoke-MaintenanceCommand, Invoke-UpdateCommand, ConvertFrom-AptSummary, Write-LogSummary