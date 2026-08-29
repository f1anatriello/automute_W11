$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvPython = Join-Path $scriptDir "venv\Scripts\python.exe"
$appScript = Join-Path $scriptDir "spotify_ad_mute.py"

if (-not (Test-Path $venvPython)) {
    Write-Error "Non trovo Python della venv: $venvPython"
    exit 1
}

if (-not (Test-Path $appScript)) {
    Write-Error "Non trovo il programma: $appScript"
    exit 1
}

Write-Host "Avvio Automute..."
& $venvPython $appScript
exit $LASTEXITCODE
