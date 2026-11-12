# Measure actual Android frame pacing while manually playing a match.
# Run from the repository root with an Android phone connected via ADB.
param(
    [string]$PackageName = 'com.example.ludo_lovers',
    [int]$Seconds = 60,
    [string]$OutputDirectory = 'test-artifacts/performance'
)

$ErrorActionPreference = 'Stop'
if ($Seconds -lt 10) { throw 'Capture at least 10 seconds.' }
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    throw 'adb is required. Install Android platform-tools first.'
}
$devices = @(adb devices | Select-String '\tdevice$')
if ($devices.Count -ne 1) {
    throw "Connect exactly one authorized Android device; found $($devices.Count)."
}
$null = adb shell pidof $PackageName
if ($LASTEXITCODE -ne 0) {
    throw "Package $PackageName is not running. Launch the game first."
}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$prefix = Join-Path $OutputDirectory "ludo-$stamp"
adb shell dumpsys gfxinfo $PackageName reset | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not reset frame statistics.' }
Write-Host "Play a match and move pawns for $Seconds seconds..."
Start-Sleep -Seconds $Seconds
$stats = @(adb shell dumpsys gfxinfo $PackageName framestats)
if ($LASTEXITCODE -ne 0) { throw 'Could not collect frame statistics.' }
$stats | Set-Content -Encoding UTF8 "$prefix-gfxinfo.txt"
$device = @(adb shell getprop ro.product.model)
$refresh = @(adb shell dumpsys display | Select-String 'mRefreshRate|refreshRate' | Select-Object -First 5)
@(
    "Captured: $(Get-Date -Format o)"
    "Package: $PackageName"
    "Device: $($device -join ' ')"
    "Duration seconds: $Seconds"
    "Display refresh data: $($refresh -join '; ')"
    'Frame budget at 60 Hz: 16.67 ms'
    'Review Janky frames and frame-time percentiles in gfxinfo output.'
    'Note: gfxinfo is Android UI rendering telemetry, not a Flutter-specific raster benchmark.'
) | Set-Content -Encoding UTF8 "$prefix-summary.txt"
Write-Host "Saved $prefix-gfxinfo.txt and $prefix-summary.txt"
