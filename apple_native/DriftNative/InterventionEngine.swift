import Foundation

struct InterventionEngine {
    /// Native counterpart to Python's `interventions.adaptive_interventions`.
    ///
    /// Future work should include local cooldowns, prompt rotation, habituation
    /// prevention, and user override. The intervention layer should stay sparse:
    /// if there is no clear benefit, the best intervention is silence.
    func message(for state: AttentionState, context: AttentionContext) -> String {
        switch state {
        case .focused, .assistedDeepWork, .developmentLoop, .researchFlow:
            return "No intervention needed."
        case .neutral:
            return "Quiet mode. Stay with what matters."
        case .passiveDrift:
            return "Pause briefly and check in with yourself."
        case .compulsiveDrift:
            return "Let the impulse settle briefly."
        case .overloaded:
            return "A short reset may help restore clarity."
        case .idlePaused:
            return "Quiet mode. Nothing needs attention."
        case .unknown:
            return "Take a second before continuing."
        }
    }
}
