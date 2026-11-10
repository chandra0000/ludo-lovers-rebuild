$ErrorActionPreference = "Stop"

# Run only after an intentional visual change has been reviewed.
Set-Location (Join-Path $PSScriptRoot "..")
flutter test --update-goldens --reporter expanded
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Golden references updated. Review every changed PNG before committing."
