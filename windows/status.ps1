[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This status check must be run on Windows.'
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$profile = Import-PowerShellDataFile -LiteralPath (Join-Path $scriptDirectory 'profile.psd1')
$registryPath = $profile.RegistryPath
$backupPath = Join-Path `
    (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'MacLikeTouchpad') `
    'precision-touchpad-backup.json'

Write-Host "Windows: $([Environment]::OSVersion.VersionString)"
Write-Host "Backup:  $(if (Test-Path -LiteralPath $backupPath) { $backupPath } else { 'not created' })"

if (-not (Test-Path -LiteralPath $registryPath)) {
    Write-Host 'Precision Touchpad: not detected' -ForegroundColor Red
    Write-Host 'Check Settings > Bluetooth & devices > Touchpad and install the OEM driver if needed.'
    exit 1
}

Write-Host 'Precision Touchpad: detected' -ForegroundColor Green
$registryKey = Get-Item -LiteralPath $registryPath
$existingNames = @($registryKey.GetValueNames())
$mismatches = 0

Write-Host ''
Write-Host ('{0,-24} {1,-9} {2,-9} {3}' -f 'Setting', 'Current', 'Expected', 'State')
Write-Host ('-' * 56)

foreach ($name in @($profile.Values.Keys | Sort-Object)) {
    $expected = [int]$profile.Values[$name]
    $exists = $existingNames -contains $name
    $current = if ($exists) { [int]$registryKey.GetValue($name) } else { '<unset>' }
    $matches = $exists -and $current -eq $expected
    if (-not $matches) { $mismatches++ }
    $state = if ($matches) { 'OK' } else { 'DIFFERS' }
    $color = if ($matches) { 'Green' } else { 'Yellow' }
    Write-Host ('{0,-24} {1,-9} {2,-9} ' -f $name, $current, $expected) -NoNewline
    Write-Host $state -ForegroundColor $color
}

Write-Host ''
Write-Host 'Manual check: Settings > Bluetooth & devices > Touchpad > Advanced gestures'
Write-Host 'Recommended four-finger swipes: Switch desktops and show desktop'

if ($mismatches -gt 0) {
    Write-Warning "$mismatches profile setting(s) differ. Run .\windows\install.ps1 to apply them."
    exit 2
}

Write-Host 'Profile status: installed' -ForegroundColor Green
