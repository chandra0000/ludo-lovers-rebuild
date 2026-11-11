[CmdletBinding()]
param(
    [string]$Serial = "emulator-5554",
    [int]$TimeoutSeconds = 600,
    [int]$PollSeconds = 5
)

$ErrorActionPreference = "Stop"

function Show-AdbDevices {
    Write-Host "ADB device inventory:"
    & adb devices -l
}

Write-Host "Restarting ADB server..."
& adb kill-server
if ($LASTEXITCODE -ne 0) {
    Write-Warning "adb kill-server returned $LASTEXITCODE; continuing with server startup."
}
& adb start-server
if ($LASTEXITCODE -ne 0) {
    throw "Unable to start the ADB server (exit code $LASTEXITCODE)."
}
Show-AdbDevices

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
Write-Host "Waiting up to $TimeoutSeconds seconds for $Serial to report state 'device'..."
while ((Get-Date) -lt $deadline) {
    $state = (& adb -s $Serial get-state 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -eq 0 -and $state -eq "device") {
        break
    }
    Start-Sleep -Seconds $PollSeconds
}
if ($state -ne "device") {
    Show-AdbDevices
    throw "Emulator $Serial did not become online within $TimeoutSeconds seconds (last state: '$state')."
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
Write-Host "Waiting up to $TimeoutSeconds seconds for sys.boot_completed=1..."
$bootCompleted = ""
while ((Get-Date) -lt $deadline) {
    $bootCompleted = (& adb -s $Serial shell getprop sys.boot_completed 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -eq 0 -and $bootCompleted -eq "1") {
        Write-Host "Android boot completed on $Serial."
        exit 0
    }
    Start-Sleep -Seconds $PollSeconds
}

Show-AdbDevices
& adb -s $Serial shell getprop sys.boot_completed
throw "Android did not complete boot within $TimeoutSeconds seconds (sys.boot_completed='$bootCompleted'). Do not run Flutter tests against this emulator."
