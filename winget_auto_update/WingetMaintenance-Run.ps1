Import-Module "$PSScriptRoot\WingetMaintenance-Tools.psm1"

Write-Host "Running Winget Auto-Updater..." -ForegroundColor Green

$LogPath = "$PSScriptRoot\winget-update.log"
"-----------------------------------" | Out-File $LogPath
"WINGET AUTOMATIC UPDATE LOG" | Out-File $LogPath -Append
"-----------------------------------" | Out-File $LogPath -Append

# 1. Check for upgradeable packages
$ListResult = Invoke-WingetCommand `
    -TaskName "List upgradeable packages" `
    -Command "winget upgrade --output json" `
    -LogPath $LogPath `
    -LogOutput:$false

$Summary = ConvertFrom-WingetSummary -JsonLines $ListResult.Output

# 2. Perform upgrades
$UpgradeResult = Invoke-WingetCommand `
    -TaskName "Upgrade all packages" `
    -Command "winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --include-unknown --include-pinned --include-explicit" `
    -LogPath $LogPath `
    -LogOutput:$true

# 3. Write summary
Write-LogSummary -SummaryObject $Summary -LogPath $LogPath

Write-Host "Winget update complete."


# -------------------------
# 7. FINAL SUMMARY AND RUNTIME CALCULATION
# -------------------------
"----------`n FINAL SUMMARY `n----------"  | Out-File $LogPath -Append

$EndTime = Get-Date
$Duration = $EndTime - $StartTime

"Automatic update completed: $Timestamp`nTotal runtime: $Duration`n(see Raspberry Pi logs)" | Out-File $LogPath -Append

$JsonSummary = [PSCustomObject]@{
    Timestamp = $Timestamp
    PiHost    = $PiHost
    DryRun    = $DryRun
    Retry     = $Retry

    Maintenance = @{
        WipeLogs     = $WipeResult
        DiskSpace    = $DiskResult
        Uptime       = $UptimeResult
        Temperature  = $TempResult
        Throttling   = $ThrottleResult
        PiHoleStatus = $PiHoleStatusResult
    }

    Updates = @{
        check = $OsCheckResult
        UpgradeablePackages = $OsUpgradeSummary."Not Upgrading"
        Summary             = $OsUpgradeSummary.Summary
        UpgradeResult       = $OsUpgradeResult
    }

    PiHoleUpdates = @{
        Check  = $PiHoleCheckResult
        Update = $PiHoleUpdateResult
    }

    PiHoleReboot = $RebootResult
    Runtime = $Duration.ToString()
}

$JsonPath = $LogPath.Replace(".log", ".json")
$JsonSummary | ConvertTo-Json -Depth 6 | Out-File $JsonPath

(Get-Date).ToString("o") | Out-File $LastRunFile

