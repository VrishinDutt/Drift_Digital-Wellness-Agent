import Foundation

enum InterventionKind: String, CaseIterable, Equatable {
    case none
    case reflectivePrompt
    case breathingReset
    case softPause
    case audioTransitionSuggestion
}

struct AttentionIntervention: Equatable {
    let kind: InterventionKind
    let title: String
    let message: String
    let choices: [String]
    let tone: String
    let shouldExpandWidget: Bool

    var hasChoices: Bool {
        !choices.isEmpty
    }

    static let none = AttentionIntervention(
        kind: .none,
        title: "No intervention needed",
        message: "Current rhythm looks steady.",
        choices: [],
        tone: "quiet",
        shouldExpandWidget: false
    )
}

struct InterventionEngine {
    /// Native counterpart to Python's `interventions.adaptive_interventions`.
    ///
    /// Future work should include local cooldowns, prompt rotation, habituation
    /// prevention, and user override. The intervention layer should stay sparse:
    /// if there is no clear benefit, the best intervention is silence.
    ///
    /// Future Cognitive Rhythm Layer / Adaptive Soundscape-inspired support can
    /// remain local and user-controlled: Deep Work Rhythm, Downshift Rhythm,
    /// Rising Energy Rhythm, Sunset / Wind-down Mode, Sunrise / Start-up Mode,
    /// and visual Breathing Cue. Do not add audio playback, microphone input,
    /// listening-history access, cloud generation, or mental-health inference.
    func intervention(
        for state: AttentionState,
        context: AttentionContext
    ) -> AttentionIntervention {
        switch state {
        case .focused, .assistedDeepWork, .developmentLoop, .researchFlow, .idlePaused:
            return .none
        case .neutral:
            return .none
        case .passiveDrift:
            return AttentionIntervention(
                kind: .reflectivePrompt,
                title: "Set a light intention",
                message: "Choose a direction before continuing.",
                choices: ["Learn", "Create", "Connect", "Unwind"],
                tone: "reflective",
                shouldExpandWidget: false
            )
        case .compulsiveDrift:
            return AttentionIntervention(
                kind: .softPause,
                title: "Let the impulse settle",
                message: "Pause briefly, then continue if it still feels intentional.",
                choices: [],
                tone: "soft-pause",
                shouldExpandWidget: false
            )
        case .overloaded:
            return AttentionIntervention(
                kind: .breathingReset,
                title: "Slow the rhythm",
                message: "Take one steady breath before continuing.",
                choices: [],
                tone: "reset",
                shouldExpandWidget: false
            )
        case .unknown:
            return .none
        }
    }

    func message(for state: AttentionState, context: AttentionContext) -> String {
        intervention(for: state, context: context).message
    }
}
