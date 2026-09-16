[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$scripts = @('install.ps1', 'status.ps1', 'uninstall.ps1', 'test.ps1')

foreach ($script in $scripts) {
    $path = Join-Path $scriptDirectory $script
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $path,
        [ref]$tokens,
        [ref]$parseErrors
    )
    if ($parseErrors.Count -gt 0) {
        throw "PowerShell syntax errors in ${script}: $($parseErrors -join '; ')"
    }
}

$profile = Import-PowerShellDataFile -LiteralPath (Join-Path $scriptDirectory 'profile.psd1')
$expectedNames = @(
    'AAPThreshold',
    'LeaveOnWithMouse',
    'PanEnabled',
    'RightClickZoneEnabled',
    'ScrollDirection',
    'TapAndDrag',
    'TapsEnabled',
    'TwoFingerTapEnabled',
    'ZoomEnabled'
)
$actualNames = @($profile.Values.Keys | Sort-Object)

if (($actualNames -join ',') -ne (($expectedNames | Sort-Object) -join ',')) {
    throw "Unexpected profile settings: $($actualNames -join ', ')"
}

foreach ($name in $actualNames) {
    $value = [int]$profile.Values[$name]
    if ($value -lt 0 -or $value -gt 4) {
        throw "Out-of-range value for ${name}: $value"
    }
}

if ($profile.RegistryPath -ne 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PrecisionTouchPad') {
    throw 'The profile targets an unexpected registry path.'
}

Write-Host 'Windows scripts and profile validated.' -ForegroundColor Green
