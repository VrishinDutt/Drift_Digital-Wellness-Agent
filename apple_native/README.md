# Drift Apple-Native Exploration

This folder is the Apple-native exploration path for **Drift_Digital-Wellness-Agent**.

The working product name is **Drift**. Drift is a privacy-first digital wellness agent focused on attentional state, humane digital interaction, and contextual self-regulation.

This is not the production app. This is not a replacement for the Python/PySide6 reference prototype. The Python desktop app remains the working cross-platform reference on the desktop-polish-and-windows-validation branch.

## Product Identity

Drift is not:

- a productivity tracker
- a parental-control tool
- a screen-time shame dashboard
- surveillance software
- a therapy chatbot
- an app blocker

Drift should feel like:

- an Apple Watch for digital health
- an ambient attention-state HUD
- a calm cockpit instrument
- a local-first behavioral copilot
- a digital nervous-system mirror
- an Apple-native attention vitals layer

Core premise:

**Attention state > screen time**

The system should care less about how long an app was open and more about whether interaction appears intentional, fragmented, passive, compulsive, idle, or overloaded.

## First Native Target

The first native target is a macOS SwiftUI HUD scaffold with mocked telemetry.

Later possibilities:

- macOS menu bar app
- floating HUD window
- LaunchAgent or background helper
- native notification/intervention layer
- iOS Screen Time companion research
- Apple Watch-style glanceable companion exploration

Do not start with iOS. Do not start with Screen Time APIs. The native path begins with a minimal macOS HUD and mocked local data.

## What Exists Here

`DriftNative/` contains conceptually compile-ready Swift source files:

- `DriftNativeApp.swift`
- `ContentView.swift`
- `HUDView.swift`
- `AttentionSnapshot.swift`
- `MockTelemetryProvider.swift`
- `BehaviorEngine.swift`
- `ContextClassifier.swift`
- `DriftAnalyzer.swift`
- `ReasoningEngine.swift`
- `InterventionEngine.swift`
- `DesignTokens.swift`

No `.xcodeproj` is generated yet. That is intentional. These files are meant to be wrapped into an Xcode project manually once the native design direction is stable.

## Privacy Boundaries

This exploration preserves the same privacy boundaries as the Python prototype:

- no screenshots
- no keystroke logging
- no clipboard access
- no page text scraping
- no private message reading
- no microphone inference
- no camera inference
- no hidden surveillance
- no punitive app blocking

Default assumption:

**private behavioral cognition should stay on-device**

Any future native telemetry must be user-granted, transparent, sparse, and local-first.

## Running Direction

For now:

1. Create a new macOS SwiftUI app in Xcode.
2. Name the target `DriftNative`.
3. Add the Swift files from `apple_native/DriftNative/`.
4. Set `DriftNativeApp.swift` as the app entrypoint.
5. Run the mocked HUD.

The first native milestone is not real telemetry. It is visual and architectural alignment: a calm, readable, Apple-native attention vitals surface.

## Current Status

Internal prototype / pre-alpha exploration.

The branch is intentionally minimal, local-first, and non-invasive.
