$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvDir = Join-Path $scriptDir "venv"
$venvPython = Join-Path $venvDir "Scripts\python.exe"
$appScript = Join-Path $scriptDir "spotify_ad_mute.py"
$requirements = Join-Path $scriptDir "requirements.txt"

function Get-ProjectPython {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Python\Python312\python.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\Python\Python311\python.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\Python\Python310\python.exe"),
        (Join-Path $env:ProgramFiles "Python312\python.exe"),
        (Join-Path $env:ProgramFiles "Python311\python.exe"),
        (Join-Path $env:ProgramFiles "Python310\python.exe")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        foreach ($version in @('3.14', '3.13', '3.12', '3.11', '3.10')) {
            $resolved = & py -$version -c "import sys; print(sys.executable)" 2>$null
            if ($LASTEXITCODE -eq 0 -and $resolved) {
                return $resolved.Trim()
            }
        }
    }

    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    return $null
}

if (-not (Test-Path $appScript)) {
    Write-Error "Non trovo il programma: $appScript"
    exit 1
}

$pyExe = Get-ProjectPython
if (-not $pyExe) {
    Write-Error "Python 3.10+ non trovato. Installa Python da https://www.python.org/downloads/windows/ e poi riavvia questo script."
    exit 1
}

if (-not (Test-Path $venvPython)) {
    if (Test-Path $venvDir) {
        Remove-Item -Recurse -Force $venvDir -ErrorAction SilentlyContinue
    }

    & $pyExe -m venv $venvDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Creazione della venv fallita."
        exit 1
    }
}

$venvPython = Join-Path $venvDir "Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    Write-Error "Non trovo Python della venv: $venvPython"
    exit 1
}

if (Test-Path $requirements) {
    & $venvPython -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Aggiornamento pip fallito."
        exit 1
    }

    & $venvPython -m pip install -r $requirements
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Installazione dipendenze fallita."
        exit 1
    }
}

& $venvPython $appScript
exit $LASTEXITCODE
