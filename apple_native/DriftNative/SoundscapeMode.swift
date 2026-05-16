import Foundation

enum SoundscapeMode: String, CaseIterable, Equatable {
    case none
    case deepWork
    case downshift
    case risingEnergy
    case startUp
    case windDown
    case breathingCue

    var displayName: String {
        switch self {
        case .none:
            return "No local cue"
        case .deepWork:
            return "Deep Work Rhythm"
        case .downshift:
            return "Downshift Rhythm"
        case .risingEnergy:
            return "Rising Energy Rhythm"
        case .startUp:
            return "Start-up Rhythm"
        case .windDown:
            return "Wind-down Rhythm"
        case .breathingCue:
            return "Breathing Cue"
        }
    }

    var defaultLocalAssetName: String? {
        switch self {
        case .none:
            return nil
        case .deepWork:
            return "deep_work_rhythm.wav"
        case .downshift:
            return "downshift_rhythm.wav"
        case .risingEnergy:
            return "rising_energy_rhythm.wav"
        case .startUp:
            return "startup_rhythm.wav"
        case .windDown:
            return "winddown_rhythm.wav"
        case .breathingCue:
            return "breathing_cue.wav"
        }
    }

    var allowsLooping: Bool {
        switch self {
        case .none, .breathingCue:
            return false
        case .deepWork, .downshift, .risingEnergy, .startUp, .windDown:
            return true
        }
    }
}

extension CognitiveRhythmPlan {
    var soundscapeMode: SoundscapeMode {
        switch mode {
        case .none:
            return .none
        case .deepWorkRhythm:
            return .deepWork
        case .risingEnergyRhythm:
            return .risingEnergy
        case .downshiftRhythm:
            return .downshift
        case .windDownRhythm:
            return .windDown
        case .startUpRhythm:
            return .startUp
        case .visualBreathingCue:
            return .breathingCue
        }
    }

    var hasSoundscapeSuggestion: Bool {
        soundscapeMode != .none
    }
}
