# Local Flutter validation — run from the repository root.
# Usage: pwsh -File scripts/validate-flutter.ps1
#        pwsh -File scripts/validate-flutter.ps1 -FixFormatting
param(
    [switch]$FixFormatting,
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$mobile = Join-Path $PSScriptRoot '../apps/mobile'
if (-not (Test-Path (Join-Path $mobile 'pubspec.yaml'))) {
    throw "Flutter project not found: $mobile"
}

Push-Location $mobile
try {
    function Invoke-Checked([string]$Name, [string]$Executable, [string[]]$Arguments) {
        Write-Host "==> $Name" -ForegroundColor Cyan
        & $Executable @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "$Name failed with exit code $LASTEXITCODE"
        }
    }

    Invoke-Checked 'Flutter version' 'flutter' @('--version')
    Invoke-Checked 'Resolve dependencies' 'flutter' @('pub', 'get')

    if ($FixFormatting) {
        Invoke-Checked 'Apply Dart formatting' 'dart' @('format', 'lib', 'test', 'integration_test')
    } else {
        Invoke-Checked 'Verify Dart formatting' 'dart' @(
            'format', '--output=none', '--set-exit-if-changed',
            'lib', 'test', 'integration_test'
        )
    }

    Invoke-Checked 'Static analysis' 'flutter' @('analyze', '--no-pub')
    if (-not $SkipTests) {
        Invoke-Checked 'Unit and widget tests' 'flutter' @('test', '--no-pub')
    }
    Write-Host 'Local Flutter validation passed.' -ForegroundColor Green
} finally {
    Pop-Location
}
