@{
    RootModule        = 'PiMaintenance-Tools.psm1'
    ModuleVersion     = '1.1.0'
    GUID              = 'a-new-guid-here'
    Author            = 'Helen'
    Description       = 'Raspberry Pi maintenance automation tools'
    FunctionsToExport = @(
        'Invoke-MaintenanceCommand',
        'Invoke-UpdateCommand',
        'ConvertFrom-AptSummary',
        'Write-LogSummary',
        'Show-Step',
        'Show-Result'
    )
    PrivateData = @{
        PSData = @{
            Tags = @("RaspberryPi", "Automation", "Maintenance")
        }
    }
}
