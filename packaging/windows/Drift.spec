# -*- mode: python ; coding: utf-8 -*-

from pathlib import Path


SPEC_DIR = Path(SPECPATH).resolve()
PROJECT_ROOT = SPEC_DIR.parents[1]
VERSION_FILE = SPEC_DIR / "version_info.txt"


a = Analysis(
    [str(PROJECT_ROOT / "desktop_app" / "main.py")],
    pathex=[str(PROJECT_ROOT)],
    binaries=[],
    datas=[],
    hiddenimports=[
        "agent.main_agent",
        "agent.runtime",
        "telemetry.activity_tracker",
        "telemetry.fallback_tracker",
        "telemetry.windows_tracker",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        "AppKit",
        "Quartz",
        "telemetry.macos_tracker",
    ],
    noarchive=False,
    optimize=0,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="Drift",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    version=str(VERSION_FILE),
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="Drift",
)
