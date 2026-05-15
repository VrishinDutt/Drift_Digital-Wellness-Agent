# Apple-Native Architecture

This document maps the Python reference architecture into a future Swift-native macOS implementation.

Python reference:

```text
Telemetry Layer
-> Context Providers
-> Behavioral Feature Extraction
-> Context Classification
-> Drift Analysis
-> Reasoning Engine
-> Adaptive Interventions
-> HUD/Desktop Layer
```

Swift-native direction:

```text
Telemetry Provider
-> Context Classifier
-> Drift Analyzer
-> Reasoning Engine
-> Intervention Engine
-> SwiftUI HUD
```

## Module Mapping

| Python Reference | Swift Native Scaffold | Purpose |
| --- | --- | --- |
| `telemetry/activity_tracker.py` | future `TelemetryProvider` protocol | Platform telemetry entrypoint |
| `telemetry/macos_tracker.py` | future `MacOSTelemetryProvider` | macOS foreground app/window metadata |
| `core/behavior_engine.py` | `BehaviorEngine.swift` | Coordinates classification, drift, reasoning, intervention |
| `ml/context_classifier.py` | `ContextClassifier.swift` | App/title to broad context |
| `ml/drift_analyzer.py` | `DriftAnalyzer.swift` | Bounded drift score |
| `agent/reasoning_engine.py` | `ReasoningEngine.swift` | Context + score to attention state |
| `interventions/adaptive_interventions.py` | `InterventionEngine.swift` | Gentle local intervention copy |
| `agent/session_timeline.py` | future `SessionTimelineStore` | Local session history |
| `context/spotify_provider.py` | future `MusicContextProvider` | User-granted audio context |
| `desktop_app/main_window.py` | `HUDView.swift` | Glanceable attention HUD |

## macOS Native Telemetry Research

Potential native tools:

- `NSWorkspace` for active application notifications and running app metadata
- AppKit application activation notifications
- Accessibility API / `AXUIElement` for user-granted window metadata
- Quartz window observation if needed
- menu bar app architecture
- local notification support
- LaunchAgent/background helper later

The native telemetry provider should stay minimal:

- foreground app identity
- foreground window title when exposed by OS accessibility APIs
- app transition timing
- idle state
- local session timeline

It must not collect:

- screenshots
- keystrokes
- clipboard content
- page body text
- private message contents
- OCR
- microphone/camera data
- hidden screen capture

If permissions are missing, the native app should degrade to `TelemetryStatus.unavailable` or `TelemetryStatus.stale` rather than crashing.

## iOS/iPadOS Later

iOS is constrained and should not be the first implementation. The later research path may include:

- `FamilyControls`
- `ManagedSettings`
- `DeviceActivity`
- Screen Time API concepts
- app shielding only if explicitly configured by the user
- device activity summaries
- limited real-time telemetry

iOS should be treated as a companion path, not the initial native foundation.

## Apple Music Later

A future `AppleMusicContextProvider` may use user-granted playback context to infer broad auditory regulation:

- playback state
- broad stimulation context
- calming or transition support
- lightweight local tags such as `calming`, `high_stimulation`, or `audio_regulation`

Avoid emotional diagnosis. Music context should never become a psychological profile.

## Future Native Interfaces

The code should remain open to future modules without forcing them now:

- `TelemetryProvider`
- `MusicContextProvider`
- `BrowserContextProvider`
- `CodingContextProvider`
- `ResearchContextProvider`
- `InterventionScheduler`
- `SessionTimelineStore`
- `PrivacyPermissionState`

These are architectural directions, not current implementation commitments.
