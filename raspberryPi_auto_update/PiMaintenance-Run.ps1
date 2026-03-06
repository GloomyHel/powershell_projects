# -------------------------
# 1. INITIAL SETUP
# -------------------------
Import-Module "$PSScriptRoot\RaspberryPiTools.psm1"
$LogPath = "C:\Users\hellz\OneDrive\Programing\powershell\powershell_projects\raspberryPi_auto_update\PiMaintenance-Report.log"
$PiHost = "thewizard@blockmagic"
$StartTime = Get-Date
$Timestamp = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")

"-----------------------------------`n RASPBERRY-PI AUTOMATIC UPDATE LOG `n-----------------------------------" | Out-File $LogPath
"Last run: $Timestamp" | Out-File $LogPath -Append

# -------------------------
# 2. TEST SSH CONNECTION
# -------------------------
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Output = ssh $PiHost "echo connected" 2>&1

if ($LASTEXITCODE -eq 0) {
    "SSH login: successful`n" | Out-File $LogPath -Append
}
else {
    "SSH login: failed" | Out-File $LogPath -Append
    "Error: $($Output[0])" | Out-File $LogPath -Append
    "Automatic update failed (see Raspberry Pi logs)`n" | Out-File $LogPath -Append
    exit
}

# -------------------------
# 3. LOOP 1: MAINTENANCE REPORT
# -------------------------
"----------`n MAINTENANCE REPORT `n----------"  | Out-File $LogPath -Append

Invoke-MaintenanceCommand `
    -TaskName "Wipe logs" `
    -OutputLabel "Wipe logs" `
    -Command "sudo rm -rf /var/log/*" `
    -PiHost $PiHost `
    -LogPath $LogPath `
    -NoOutput

Invoke-MaintenanceCommand `
    -TaskName "Check disk space" `
    -OutputLabel "Disk space" `
    -Command "df -h /" `
    -PiHost $PiHost `
    -LogPath $LogPath `
    -MultiLine

Invoke-MaintenanceCommand `
    -TaskName "Check uptime" `
    -OutputLabel "Uptime" `
    -Command "uptime -p" `
    -PiHost $PiHost `
    -LogPath $LogPath

Invoke-MaintenanceCommand `
    -TaskName "Check temperature" `
    -OutputLabel "Temperature" `
    -Command "vcgencmd measure_temp" `
    -PiHost $PiHost `
    -LogPath $LogPath

Invoke-MaintenanceCommand `
    -TaskName "Check throttling" `
    -OutputLabel "Throttling" `
    -Command "vcgencmd get_throttled" `
    -PiHost $PiHost `
    -LogPath $LogPath

Invoke-MaintenanceCommand `
    -TaskName "Check Pi-hole status" `
    -OutputLabel "Pi-hole status" `
    -Command "pihole status" `
    -PiHost $PiHost `
    -LogPath $LogPath `
    -MultiLine

# -------------------------
# 4. LOOP 2: OS UPDATES REPORT
# -------------------------
"----------`n OS UPDATES REPORT `n----------"  | Out-File $LogPath -Append

Invoke-MaintenanceCommand `
    -TaskName "Check for package updates" `
    -OutputLabel "Number of package updates available" `
    -Command "apt list --upgradeable 2>/dev/null | wc -l" `
    -PiHost $PiHost `
    -LogPath $LogPath

# 1. Get list of upgradeable packages
$ListResult = Invoke-UpdateCommand `
    -TaskName "List upgradeable packages" `
    -Command "apt list --upgradeable 2>/dev/null" `
    -PiHost $PiHost `
    -LogPath $LogPath `
    -LogOutput:$false

$UpgradeSummary = ConvertFrom-AptSummary -Output $ListResult.Output

# 3. Perform the upgrade (output ignored in log)
Invoke-UpdateCommand `
    -TaskName "Package upgrades" `
    -Command "sudo apt upgrade -y" `
    -PiHost $PiHost `
    -LogPath $LogPath `
    -LogOutput:$false

Write-LogSummary -SummaryObject $UpgradeSummary -LogPath $LogPath

# -------------------------
# 5. LOOP 3: PI-HOLE UPDATES REPORT
# -------------------------
"----------`n PI-HOLE UPDATES REPORT `n----------"  | Out-File $LogPath -Append

Invoke-UpdateCommand `
    -TaskName "Check for Pi-hole updates" `
    -Command "pihole -v" `
    -PiHost $PiHost `
    -LogPath $LogPath `
    -LogOutput

Invoke-UpdateCommand `
    -TaskName "Pi-hole updates" `
    -Command "sudo pihole -up" `
    -PiHost $PiHost `
    -LogPath $LogPath `
    -LogOutput:$false

# -------------------------
# 6. REBOOT (still optional)
# -------------------------
"----------`n RASPBERRY-PI REBOOT `n----------"  | Out-File $LogPath -Append
# You can later swap this to Invoke-UpdateCommand if you want logged reboot.

# -------------------------
# 10. FINAL SUMMARY AND RUNTIME CALCULATION
# -------------------------
"----------`n FINAL SUMMARY `n----------"  | Out-File $LogPath -Append

$EndTime = Get-Date
$Duration = $EndTime - $StartTime
"Automatic update completed: $Timestamp`nTotal runtime: $Duration`n(see Raspberry Pi logs)" | Out-File $LogPath -Append