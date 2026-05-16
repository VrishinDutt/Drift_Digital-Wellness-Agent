import Foundation

enum CognitiveRhythmMode: String, CaseIterable, Equatable {
    case none
    case deepWorkRhythm
    case risingEnergyRhythm
    case downshiftRhythm
    case windDownRhythm
    case startUpRhythm
    case visualBreathingCue

    var displayName: String {
        switch self {
        case .none:
            return "No rhythm cue"
        case .deepWorkRhythm:
            return "Deep Work Rhythm"
        case .risingEnergyRhythm:
            return "Rising Energy Rhythm"
        case .downshiftRhythm:
            return "Downshift Rhythm"
        case .windDownRhythm:
            return "Wind-down Rhythm"
        case .startUpRhythm:
            return "Start-up Rhythm"
        case .visualBreathingCue:
            return "Visual Breathing Cue"
        }
    }
}

enum RhythmIntensity: String, CaseIterable, Equatable {
    case silent
    case low
    case medium

    var displayName: String {
        switch self {
        case .silent:
            return "Silent"
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        }
    }
}

enum SoundscapeTexture: String, CaseIterable, Equatable {
    case none
    case nearSilence
    case steadyLowTexture
    case softPulse
    case gentleLift
    case dimWarmth

    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .nearSilence:
            return "Near silence"
        case .steadyLowTexture:
            return "Steady low texture"
        case .softPulse:
            return "Soft pulse"
        case .gentleLift:
            return "Gentle lift"
        case .dimWarmth:
            return "Dim warmth"
        }
    }
}

struct CognitiveRhythmPlan: Equatable {
    let mode: CognitiveRhythmMode
    let intensity: RhythmIntensity
    let texture: SoundscapeTexture
    let cadence: String
    let guidance: String
    let interventionMessage: String
    let shouldSurface: Bool
    let boundary: String

    var displayName: String {
        mode.displayName
    }

    static let none = CognitiveRhythmPlan(
        mode: .none,
        intensity: .silent,
        texture: .none,
        cadence: "No cue",
        guidance: "No rhythm cue is needed right now.",
        interventionMessage: "Current rhythm looks steady.",
        shouldSurface: false,
        boundary: CognitiveRhythmLayer.privacyBoundary
    )
}

struct CognitiveRhythmLayer {
    static let privacyBoundary = "No audio playback, microphone, Apple Music, Endel API, cloud inference, or extra telemetry."

    /// Local-only scaffold for soundscape-inspired support.
    ///
    /// This layer names a rhythm cue and UI copy. It does not play audio, inspect
    /// listening history, read microphone input, call music services, or infer
    /// mental state. Inputs are limited to the already-derived attention state,
    /// coarse context, drift score, and local time of day.
    func plan(
        for state: AttentionState,
        context: AttentionContext,
        driftScore: Int,
        date: Date = Date()
    ) -> CognitiveRhythmPlan {
        if state == .idlePaused || context == .paused {
            return .none
        }

        if state == .overloaded {
            return plan(
                mode: .visualBreathingCue,
                intensity: .low,
                texture: .nearSilence,
                cadence: "One slow visual cycle",
                guidance: "Keep stimulation low and make the cue visual only.",
                message: "Lower the rhythm for one breath.",
                shouldSurface: true
            )
        }

        if state == .compulsiveDrift {
            return plan(
                mode: .downshiftRhythm,
                intensity: .low,
                texture: .nearSilence,
                cadence: "Slower, less novel",
                guidance: "Suggest a quieter transition before the next action.",
                message: "Shift to a quieter rhythm before continuing.",
                shouldSurface: true
            )
        }

        if state == .passiveDrift {
            if localDaypart(for: date) == .lateEvening {
                return plan(
                    mode: .windDownRhythm,
                    intensity: .low,
                    texture: .dimWarmth,
                    cadence: "Warm and unhurried",
                    guidance: "Offer a wind-down cue without interpreting mood or health.",
                    message: "Let the rhythm soften before the next choice.",
                    shouldSurface: true
                )
            }

            return plan(
                mode: .risingEnergyRhythm,
                intensity: .medium,
                texture: .gentleLift,
                cadence: "Light forward motion",
                guidance: "Offer a gentle energy shift without forcing a block.",
                message: "Try a lighter rhythm and choose the next step.",
                shouldSurface: true
            )
        }

        if context == .audioRegulation {
            return plan(
                mode: .downshiftRhythm,
                intensity: driftScore > 30 ? .low : .silent,
                texture: .steadyLowTexture,
                cadence: "Steady and low novelty",
                guidance: "Treat audio regulation as user-controlled context, not telemetry to inspect.",
                message: "Keep the rhythm steady and low-friction.",
                shouldSurface: driftScore > 30
            )
        }

        if isWorkAligned(context) {
            return plan(
                mode: localDaypart(for: date) == .earlyMorning ? .startUpRhythm : .deepWorkRhythm,
                intensity: .silent,
                texture: .steadyLowTexture,
                cadence: "Stable and unobtrusive",
                guidance: "Preserve flow by keeping the cue silent unless drift rises.",
                message: "Hold the steady rhythm.",
                shouldSurface: false
            )
        }

        return .none
    }

    private func plan(
        mode: CognitiveRhythmMode,
        intensity: RhythmIntensity,
        texture: SoundscapeTexture,
        cadence: String,
        guidance: String,
        message: String,
        shouldSurface: Bool
    ) -> CognitiveRhythmPlan {
        CognitiveRhythmPlan(
            mode: mode,
            intensity: intensity,
            texture: texture,
            cadence: cadence,
            guidance: guidance,
            interventionMessage: message,
            shouldSurface: shouldSurface,
            boundary: Self.privacyBoundary
        )
    }

    private func isWorkAligned(_ context: AttentionContext) -> Bool {
        switch context {
        case .deepWork, .assistedWork, .development, .research:
            return true
        case .audioRegulation, .paused, .generalBrowsing, .passiveConsumption, .unknown:
            return false
        }
    }

    private func localDaypart(for date: Date) -> LocalDaypart {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 5..<10:
            return .earlyMorning
        case 20...23, 0..<5:
            return .lateEvening
        default:
            return .day
        }
    }
}

private enum LocalDaypart {
    case earlyMorning
    case day
    case lateEvening
}
