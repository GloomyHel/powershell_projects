<# winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --include-unknown --include-pinned  --include-explicit
#>

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
# LAYER 4: PUBLIC WRAPPERS
# -------------------------

function Invoke-WingetCommand {
    <#
    .SYNOPSIS
        Runs a winget command, logs success/failure and logs output in a consistent format.
    .PARAMETER TaskName
        Descriptive name for the task (e.g., "Check disk space").
    .PARAMETER OutputLabel
        Label for the output section (e.g., "Disk space"). Defaults to TaskName.
    .PARAMETER Command
        The winget command to run.
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
        [string]$LogPath,

        [Parameter()]
        [switch]$LogOutput

    )
    Show-Step $TaskName

    $raw = Invoke-Expression $Command 2>&1
    $success = $LASTEXITCODE -eq 0
    $lines = ($raw | Out-String).Trim().Split("`n")
    
    # Log success/failure
    if ($success) {
        "{$TaskName}: successful" | Out-File $LogPath -Append
    }
    else {
        "{$TaskName}: failed" | Out-File $LogPath -Append
        "ERROR: $($lines[0])`n" | Out-File $LogPath -Append
        }
    }

    # Terminal output
    Show-Result $TaskName $success

    # Log output
    if ($success -and $LogOutput) {
        "{$TaskName} output:" | Out-File $LogPath -Append
        $lines | ForEach-Object { "    $_" | Out-File $LogPath -Append }
        "" | Out-File $LogPath -Append
    }

    return [PSCustomObject]@{
        Success = $success
        Output  = $lines
        Error   = if ($success) { $null } else { $lines[0] }
    }
   

function ConvertFrom-WingetSummary {
    <#
    .SYNOPSIS
        Generates a stable summary of upgradeable packages using
        `winget list --upgradeable` output.
    .PARAMETER Output
        Raw output from `winget list --upgradeable`.
    #>
    param([string[]]$JsonLines)

    $json = $JsonLines -join "`n" | ConvertFrom-Json

    $packages = $json | Select-Object -ExpandProperty AvailableVersions -ErrorAction Ignore


    Return [PSCustomObject]@{
            "Upgrading"      = @()
            "Not Upgrading"  = $json.Id
            "Summary"        = @(
                "Upgrading: 0",
                "Installing: 0",
                "Removing: 0",
                "Not Upgrading: $($json.Count)"
            )
            "Errors"         = @()
   
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

Export-ModuleMember -Function `
    Invoke-WingetCommand, `
    ConvertFrom-WingetSummary, `
    Write-LogSummary, `
    Show-Step, `
    Show-Result