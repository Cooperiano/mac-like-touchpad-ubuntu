[CmdletBinding(SupportsShouldProcess = $true)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This uninstaller must be run on Windows.'
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$profile = Import-PowerShellDataFile -LiteralPath (Join-Path $scriptDirectory 'profile.psd1')
$registryPath = $profile.RegistryPath
$stateDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'MacLikeTouchpad'
$backupPath = Join-Path $stateDirectory 'precision-touchpad-backup.json'

if (-not (Test-Path -LiteralPath $registryPath)) {
    throw 'The Precision Touchpad settings key is not available for this account.'
}

if (-not (Test-Path -LiteralPath $backupPath)) {
    throw "No original-settings backup was found at $backupPath. Nothing was changed."
}

$backup = Get-Content -LiteralPath $backupPath -Raw | ConvertFrom-Json
if ([int]$backup.SchemaVersion -ne [int]$profile.SchemaVersion) {
    throw "Unsupported backup schema version: $($backup.SchemaVersion)"
}

$allowedNames = @($profile.Values.Keys)
foreach ($entry in @($backup.Values)) {
    $name = [string]$entry.Name
    if ($allowedNames -notcontains $name) {
        throw "The backup contains an unexpected setting name: $name"
    }

    if ([bool]$entry.WasPresent) {
        $value = [int]$entry.Value
        if ($PSCmdlet.ShouldProcess("$registryPath\$name", "Restore DWORD to $value")) {
            New-ItemProperty -LiteralPath $registryPath -Name $name -Value $value `
                -PropertyType DWord -Force | Out-Null
        }
    } elseif ($PSCmdlet.ShouldProcess("$registryPath\$name", 'Remove the value created by this project')) {
        Remove-ItemProperty -LiteralPath $registryPath -Name $name -ErrorAction SilentlyContinue
    }
}

if ($PSCmdlet.ShouldProcess($backupPath, 'Remove the consumed backup')) {
    Remove-Item -LiteralPath $backupPath -Force
    if ((Get-ChildItem -LiteralPath $stateDirectory -Force | Measure-Object).Count -eq 0) {
        Remove-Item -LiteralPath $stateDirectory -Force
    }
}

Write-Host 'The original Precision Touchpad settings were restored.' -ForegroundColor Green
Write-Host 'Review Settings > Bluetooth & devices > Touchpad > Advanced gestures manually.'
