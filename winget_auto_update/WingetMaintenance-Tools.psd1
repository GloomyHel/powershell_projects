@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'WingetMaintenance-Tools.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'b8c1e5e0-9f4a-4f4c-9c1c-123456789abc'

    # Author of this module
    Author = 'Helen Kaye'

    # Description of the module
    Description = 'Tools for automated Winget maintenance and update reporting.'

    # Minimum PowerShell version required
    PowerShellVersion = '5.1'

    # Functions to export
    FunctionsToExport = @(
        'Show-Step',
        'Show-Result',
        'Invoke-WingetCommand',
        'ConvertFrom-WingetSummary',
        'Write-LogSummary'
    )

    # No cmdlets, aliases, or variables exported
    CmdletsToExport   = @()
    AliasesToExport   = @()
    VariablesToExport = @()

    # Private data (optional)
    PrivateData = @{}
}
