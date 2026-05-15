# Privacy Commitments

Drift is privacy-first and local-first by default.

Private behavioral cognition should stay on-device unless a future user explicitly chooses an optional external integration.

## Strict Non-Collection Boundaries

The Apple-native path must not collect:

- screenshots
- screen recordings
- OCR of screen contents
- keystrokes
- clipboard contents
- page body text
- private message text
- microphone data
- camera data
- hidden browser content
- hidden surveillance data

## Allowed Telemetry Categories

Only these categories are acceptable for future native telemetry:

- foreground app identity
- foreground window title where exposed by OS/browser accessibility APIs
- app transition frequency
- session duration
- idle state
- user-granted music/audio context
- local intervention history
- local session timeline

## Permission Philosophy

Permissions must be:

- user-granted
- transparent
- explainable
- revocable
- non-coercive

If a permission is unavailable, Drift should degrade gracefully.

## Intervention Ethics

Drift restores agency. It does not enforce obedience.

Good copy:

- "Pause briefly and check in with yourself."
- "Slow the transition for a moment."
- "Take a second before continuing."
- "A short reset may help restore clarity."

Forbidden tone:

- "Stop scrolling."
- "You wasted time."
- "You are addicted."
- "Productivity lost."
- "Limit exceeded."
- "You failed."

## Local Storage

Future local storage should prefer:

- transparent local files or app containers
- short session timelines
- user-clearable history
- sparse intervention memory

Avoid hidden behavioral databases. Avoid cloud-first profiling.
