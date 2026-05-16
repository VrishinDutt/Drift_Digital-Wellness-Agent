import Foundation

enum InterventionKind: String, CaseIterable, Equatable {
    case none
    case reflectivePrompt
    case breathingReset
    case softPause
    case rhythmTransitionSuggestion
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
    /// Cognitive Rhythm Layer support remains local and user-controlled. It may
    /// surface soundscape-inspired copy, but must not add audio playback,
    /// microphone input, listening-history access, cloud generation, or
    /// mental-health inference.
    func intervention(
        for state: AttentionState,
        context: AttentionContext,
        rhythmPlan: CognitiveRhythmPlan = .none
    ) -> AttentionIntervention {
        switch state {
        case .focused, .assistedDeepWork, .developmentLoop, .researchFlow, .idlePaused:
            return .none
        case .neutral:
            return .none
        case .passiveDrift:
            if rhythmPlan.shouldSurface {
                return AttentionIntervention(
                    kind: .rhythmTransitionSuggestion,
                    title: rhythmPlan.displayName,
                    message: rhythmPlan.interventionMessage,
                    choices: ["Lower stimulation", "Choose next step"],
                    tone: "rhythm",
                    shouldExpandWidget: false
                )
            }

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
                title: rhythmPlan.shouldSurface ? rhythmPlan.displayName : "Let the impulse settle",
                message: rhythmPlan.shouldSurface
                    ? rhythmPlan.interventionMessage
                    : "Pause briefly, then continue if it still feels intentional.",
                choices: [],
                tone: "soft-pause",
                shouldExpandWidget: false
            )
        case .overloaded:
            return AttentionIntervention(
                kind: .breathingReset,
                title: rhythmPlan.shouldSurface ? rhythmPlan.displayName : "Slow the rhythm",
                message: rhythmPlan.shouldSurface
                    ? rhythmPlan.interventionMessage
                    : "Take one steady breath before continuing.",
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
