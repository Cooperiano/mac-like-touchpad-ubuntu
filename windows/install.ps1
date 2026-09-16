[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$NoSettings
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This installer must be run on Windows.'
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$profile = Import-PowerShellDataFile -LiteralPath (Join-Path $scriptDirectory 'profile.psd1')
$registryPath = $profile.RegistryPath

if (-not (Test-Path -LiteralPath $registryPath)) {
    throw @'
Windows did not expose the Precision Touchpad settings key for this account.
Install the laptop manufacturer's current touchpad driver, then confirm that
Settings > Bluetooth & devices > Touchpad is available before trying again.
'@
}

$stateDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'MacLikeTouchpad'
$backupPath = Join-Path $stateDirectory 'precision-touchpad-backup.json'
$registryKey = Get-Item -LiteralPath $registryPath

if (-not (Test-Path -LiteralPath $backupPath)) {
    $existingNames = @($registryKey.GetValueNames())
    $backupValues = foreach ($name in @($profile.Values.Keys | Sort-Object)) {
        $wasPresent = $existingNames -contains $name
        [pscustomobject]@{
            Name       = $name
            WasPresent = $wasPresent
            Value      = if ($wasPresent) { [int]$registryKey.GetValue($name) } else { $null }
        }
    }

    $backup = [ordered]@{
        SchemaVersion = $profile.SchemaVersion
        CreatedAtUtc  = [DateTime]::UtcNow.ToString('o')
        Values        = @($backupValues)
    }

    if ($PSCmdlet.ShouldProcess($backupPath, 'Create the original-settings backup')) {
        New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null
        $backup | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $backupPath -Encoding UTF8
        Write-Host "Saved the original settings to $backupPath"
    }
} else {
    Write-Host "Keeping the existing original-settings backup at $backupPath"
}

foreach ($name in @($profile.Values.Keys | Sort-Object)) {
    $value = [int]$profile.Values[$name]
    if ($PSCmdlet.ShouldProcess("$registryPath\$name", "Set DWORD to $value")) {
        New-ItemProperty -LiteralPath $registryPath -Name $name -Value $value `
            -PropertyType DWord -Force | Out-Null
    }
}

Write-Host ''
Write-Host 'The supported Windows touchpad profile is installed.' -ForegroundColor Green
Write-Host 'For the closest four-finger layout, open Advanced gestures and set:'
Write-Host '  Swipes: Switch desktops and show desktop'
Write-Host '  Taps:   Middle mouse button (or Nothing, if preferred)'
Write-Host ''
Write-Warning 'Windows does not expose system-wide three-finger drag to background apps. Use tap-tap-drag as the safe drag fallback.'

if (-not $NoSettings -and -not $WhatIfPreference) {
    Start-Process 'ms-settings:devices-touchpad'
}
