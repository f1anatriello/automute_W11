$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvDir = Join-Path $scriptDir "venv"
$venvPython = Join-Path $venvDir "Scripts\python.exe"
$appScript = Join-Path $scriptDir "spotify_ad_mute.py"
$requirements = Join-Path $scriptDir "requirements.txt"

if (-not (Test-Path $appScript)) {
    throw "Non trovo il programma: $appScript"
}

if (-not (Test-Path $venvPython)) {
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        & py -3.11 -m venv $venvDir
    } else {
        $python = Get-Command python -ErrorAction SilentlyContinue
        if (-not $python) {
            throw "Python non trovato. Installa Python 3.11 o superiore."
        }
        & $python.Source -m venv $venvDir
    }

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $venvPython)) {
        throw "Creazione della venv fallita."
    }
}

& $venvPython -c "import pycaw, winrt.windows.foundation, winrt.windows.media.control, comtypes" 2>$null
if ($LASTEXITCODE -ne 0) {
    if (-not (Test-Path $requirements)) {
        throw "Dipendenze mancanti e requirements.txt non trovato."
    }

    & $venvPython -m pip install -r $requirements
    if ($LASTEXITCODE -ne 0) {
        throw "Installazione dipendenze fallita."
    }
}

& $venvPython $appScript
exit $LASTEXITCODE
