# Path to the config file (relative to this module)
$ConfigPath = Join-Path $PSScriptRoot "PiMaintenance.config.json"

function Get-Config {
    if (-not (Test-Path $ConfigPath)) {
        throw "Config file not found: $ConfigPath"
    }

    try {
        $json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        throw "Config file is not valid JSON: $ConfigPath"
    }

    return $json
}

function Get-LogPath {
    $config = Get-Config
    $path = $config.LogPath
    $dir  = Split-Path $path

    if (-not (Test-Path $dir)) {
        throw "Log directory does not exist: $dir"
    }

    return $path
}

function Get-PiHost {
    $config = Get-Config
    $pihost = $config.PiHost

    if ([string]::IsNullOrWhiteSpace($pihost)) {
        throw "PiHost is empty — check PiMaintenance.config.json"
    }

    return $pihost
}

function Get-RetrySettings {
    $config = Get-Config

    return @{
        RetryCount       = $config.RetryCount
        RetryDelaySeconds = $config.RetryDelaySeconds
    }
}

function Get-DryRun {
    $config = Get-Config
    return [bool]$config.DryRun
}


Export-ModuleMember -Function Get-LogPath, Get-PiHost, Get-RetrySettings, Get-DryRun
