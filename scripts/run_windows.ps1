[CmdletBinding()]
param(
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$VenvDir = Join-Path $RepoRoot ".venv"
$PythonExe = Join-Path $VenvDir "Scripts\python.exe"

function New-DriftVenv {
    if (Test-Path $PythonExe) {
        return
    }

    $PyLauncher = Get-Command py -ErrorAction SilentlyContinue

    if ($PyLauncher) {
        & py -3 -m venv $VenvDir
    } else {
        & python -m venv $VenvDir
    }
}

Set-Location $RepoRoot
New-DriftVenv

if (-not (Test-Path $PythonExe)) {
    throw "Python virtual environment was not created at $VenvDir"
}

if (-not $SkipInstall) {
    & $PythonExe -m pip install --upgrade pip
    & $PythonExe -m pip install -r requirements.txt
    & $PythonExe -m pip install -r requirements-windows.txt
}

& $PythonExe -m desktop_app.main
