# Digital Wellness Agent Data Points

This project is currently in the privacy-preserving telemetry stage. The goal is to learn attention patterns from app and window context without collecting page contents, URLs, keystrokes, screenshots, clipboard contents, or message text.

## Current Non-Invasive Log Fields

Each new row in `data/activity_log.json` uses JSON Lines format and includes:

| Field | Why it helps | Privacy note |
| --- | --- | --- |
| `timestamp` | Orders samples and estimates duration | No content |
| `sample_interval_seconds` | Makes duration math accurate when interval changes | No content |
| `active_app` | Detects app-level context and switching | App name only |
| `active_app_bundle_id` | Gives a stable app identifier across display-name changes | App identifier only |
| `window_title` | Infers broad context such as work, browsing, passive consumption | Title only, no page body |
| `title_source` | Explains whether title came from Safari or the window server | Debug metadata |
| `active_context` | Stores the local classification at capture time | Derived from app/title |
| `idle_seconds` | Detects pauses without reading input | Time since input only |
| `is_idle` | Separates active use from away-from-keyboard time | Derived from idle time |
| `app_changed` | Marks app switches directly | Derived |
| `title_changed` | Marks tab/window changes, useful for Safari drift | Derived |
| `context_changed` | Marks movement between work/browsing/passive states | Derived |
| `seconds_since_last_sample` | Detects gaps in tracking | Derived |
| `seconds_in_current_context` | Estimates current streak length | Derived |
| `context_started_at` | Anchors the current streak | Derived |
| `browser` | For Safari and Chromium browsers, stores active tab title and source metadata | Explicitly excludes URL and page text |
| `privacy` | Self-documents excluded sensitive collection | Flags are false for invasive fields |
| `collector` | Identifies which module wrote the row | Debug metadata |
| `deduplicated_samples` | Counts unchanged samples skipped before an emitted row | Derived |

The active telemetry log rotates locally when it reaches the configured size
cap. Recent runtime analysis only needs the bounded tail of the JSONL stream.

## Explicitly Excluded

- Full URLs
- Browser history
- Page text
- Search query extraction
- Keystrokes
- Screenshots or screen recording
- Clipboard contents
- Camera input
- Microphone input
- File contents
- Message contents

## Useful Next Candidates

- `session_id`: group samples into work sessions after long idle gaps.
- `intervention_id`: connect an intervention to later behavior without storing private content.
- `user_response`: optional button-level feedback such as `continue`, `pause`, or `dismiss`.
- `local_goal`: optional user-entered intention for a session, stored only if explicitly provided.
- `session_summary`: derived daily totals by context, not raw sensitive content.

## Commands

Stop legacy telemetry processes without matching unrelated Python jobs:

```bash
pkill -f "telemetry[.]activity_tracker"
pkill -f "telemetry/activity_tracker[.]py"
```

The same cleanup is available as:

```bash
sh tools/stop_legacy_telemetry.sh
```

Capture one sample without writing it:

```bash
./venv/bin/python -m telemetry.activity_tracker --once
```

Start continuous tracking:

```bash
./venv/bin/python -m telemetry.activity_tracker --interval 1 --quiet
```

Write every sample instead of deduplicating repeated context:

```bash
./venv/bin/python -m telemetry.activity_tracker --interval 1 --no-dedup
```

Summarize collected data points:

```bash
./venv/bin/python telemetry/session_analyzer.py
```

Preview a log cleanup that preserves only schema v2 rows:

```bash
./venv/bin/python tools/clean_telemetry_log.py
```

Apply that cleanup with an automatic backup of the original mixed log:

```bash
./venv/bin/python tools/clean_telemetry_log.py --apply
```

Run the full agent:

```bash
./venv/bin/python -m agent.runtime
```
