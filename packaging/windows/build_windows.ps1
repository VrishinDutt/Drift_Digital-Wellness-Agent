[CmdletBinding()]
param(
    [switch]$SkipInstall,
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
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
    & $PythonExe -m pip install pyinstaller
}

if (-not $SkipTests) {
    & $PythonExe -m unittest discover -s tests
    & $PythonExe -m compileall agent core context desktop_app interventions ml telemetry ui main.py
}

& $PythonExe -m PyInstaller --clean --noconfirm packaging\windows\Drift.spec

$OutputExe = Join-Path $RepoRoot "dist\Drift\Drift.exe"
Write-Host "Build complete: $OutputExe"
