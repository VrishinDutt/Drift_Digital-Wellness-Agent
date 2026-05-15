# Apple-Native Roadmap

## Phase 0: SwiftUI Mock HUD

Goal: Create an Apple-native visual and architectural foundation.

- SwiftUI HUD with mocked attention snapshots
- state ring
- calm dark glass aesthetic
- state/context/drift/intervention display
- no real telemetry
- no permissions required

## Phase 1: macOS Native Foreground App Telemetry

Goal: Replace mock input with minimal native telemetry.

- investigate `NSWorkspace`
- investigate app activation notifications
- investigate Accessibility API / `AXUIElement`
- report foreground app/window title where user-granted
- fail gracefully when permissions are missing

No screenshots, keystrokes, clipboard access, page text, or hidden content capture.

## Phase 2: Menu Bar + Floating HUD

Goal: Make Drift ambient.

- menu bar status item
- compact floating HUD
- quick pause/resume
- local privacy/status controls
- low-frequency updates

## Phase 3: Native Reasoning Engine Parity

Goal: Reach behavioral parity with the Python reference.

- context classification parity
- drift scoring parity
- assisted deep work calibration
- passive/compulsive drift calibration
- idle/paused handling
- local intervention cooldowns

## Phase 4: Apple Music / Ambient Context Provider

Goal: Explore user-granted audio context.

- playback state
- broad stimulation context
- calming/transition suggestions
- no emotional diagnosis
- no cloud behavioral profile

## Phase 5: iOS Screen Time Companion Research

Goal: Research constraints and user value.

- FamilyControls
- ManagedSettings
- DeviceActivity
- Screen Time limitations
- app shielding only if explicitly user-configured

iOS remains a companion path, not the initial implementation.

## Phase 6: Apple Watch-Style Glanceable Companion

Goal: Explore an attention vitals companion.

- glanceable state
- sparse interventions
- local sync strategy research
- privacy-first wearable UX

This should only happen if the macOS native foundation proves useful.
