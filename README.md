# Digital Wellness Agent

Digital Wellness Agent is a local-first attentional-state prototype. It observes non-invasive foreground-window context, estimates attention state and drift pressure, and presents a calm PySide6 HUD called **Intentional**.

**Status:** internal prototype / pre-alpha.

The project is not a productivity dashboard, screen-time scolding tool, parental-control app, surveillance tool, or app blocker. The guiding principle is:

**Attention state > screen time.**

## Philosophy

The app is meant to feel like an Apple Watch-style digital health HUD for computer attention: quiet, ambient, contextual, and non-judgmental. It should help notice when digital interaction becomes fragmented, passive, automatic, or overloaded, while staying out of the way during focused work and assisted development loops.

## Privacy Boundaries

The project intentionally avoids invasive telemetry:

- No screenshots
- No keystroke logging
- No clipboard access
- No page text scraping
- No private message reading
- No punitive blocking
- No cloud-first behavioral profiling

Telemetry is local and minimal:

- foreground app/process
- foreground window title where the OS exposes it
- browser tab title on macOS where AppleScript access is available
- context classification
- drift score
- session timeline
- optional Spotify playback context

## Architecture

The runtime keeps the behavioral pipeline platform-agnostic:

Telemetry -> Context Providers -> Drift Analysis -> Reasoning -> Intervention -> HUD

Key folders:

- `agent/` runtime orchestration, memory, session timeline
- `core/` behavior engine and paths
- `context/` optional context providers such as Spotify
- `ml/` context classification and drift scoring
- `telemetry/` platform trackers and log loading
- `desktop_app/` PySide6 HUD
- `data/` local runtime state, ignored by git except `.gitkeep`

## macOS Setup

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements-macos.txt
```

Run a one-shot telemetry smoke test:

```bash
python -m telemetry.activity_tracker --once
```

Run the desktop HUD:

```bash
python -m desktop_app.main
```

macOS telemetry uses Quartz window metadata and NSWorkspace. Browser semantic title support uses AppleScript for supported browsers. It does not collect URLs or page text.

## Windows Setup

```powershell
python -m venv venv
venv\Scripts\activate
pip install -r requirements-windows.txt
```

Run the Windows smoke-test path:

```powershell
python -m compileall agent core context interventions ml telemetry ui desktop_app main.py
python -m telemetry.activity_tracker --once
python -m desktop_app.main
```

Windows telemetry uses `pywin32` and `psutil` to read:

- foreground window handle
- foreground window title
- process id
- process executable/app name
- idle duration via Windows last-input timestamp

It does not import Quartz, AppKit, or AppleScript on Windows.

## Optional Spotify Setup

Spotify is optional. If credentials are absent or playback is unavailable, the app continues without audio context.

1. Copy `.env.example` to `.env`.
2. Fill in:

```bash
SPOTIFY_CLIENT_ID=
SPOTIFY_CLIENT_SECRET=
SPOTIFY_REDIRECT_URI=http://127.0.0.1:8888/callback
```

3. Restart the app.

The Spotify provider only infers broad audio context such as stimulation, calming, and auditory regulation.

## Running The App

```bash
python -m desktop_app.main
```

Use **Start** to begin live telemetry. Use **Stop** to stop the tracker. Use **Expand** for diagnostics such as latest app, latest context, telemetry freshness, rows used, and session timeline.

Expanded mode also shows the active telemetry platform, adapter, and permission/status signal so macOS and Windows collaborators can quickly tell whether the native tracker is running or a safe fallback is active.

## Demo Mode

Click **Demo** in the HUD. Demo Mode cycles through mocked snapshots without live telemetry:

1. Focused / Deep Work / CCS 15
2. Assisted Deep Work / Development Loop / CCS 30
3. Passive Drift / General Browsing / CCS 45
4. Compulsive Drift / Passive Consumption / CCS 75
5. Overloaded / Unknown Context / CCS 90

Demo Mode is useful for presentations and UI testing.

## Reset Session

Expanded mode includes **Reset Session**. It archives current local telemetry and timeline files before clearing active runtime state. It never silently deletes session data without a backup.

## Known Limitations

- Window title availability depends on OS permissions and app behavior.
- macOS browser tab title access may require Automation permissions.
- Windows browser semantic context currently relies on foreground window titles only.
- The model is a lightweight MVP and should be treated as an attentional-state heuristic, not a clinical or diagnostic system.
- Runtime data is local and ignored by git.

## Troubleshooting

If PySide6 is missing:

```bash
pip install -r requirements.txt
```

If macOS telemetry falls back to `Unknown`, check Accessibility and Automation permissions for the terminal or Python environment running the app.

If Windows telemetry falls back to `Unknown`, confirm `requirements-windows.txt` installed successfully and run:

```powershell
python -m telemetry.activity_tracker --once
```

If Spotify context is unavailable, verify `.env` exists and playback is active. The app should still run without Spotify.
