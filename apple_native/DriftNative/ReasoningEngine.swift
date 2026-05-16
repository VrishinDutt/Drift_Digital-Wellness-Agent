import Foundation

struct ReasoningEngine {
    /// Native counterpart to Python's `agent.reasoning_engine`.
    ///
    /// This layer should remain humane: it turns behavioral signals into an
    /// attention-state interpretation, not a performance judgment.
    func inferState(
        context: AttentionContext,
        driftScore: Int,
        isIdle: Bool
    ) -> AttentionState {
        if isIdle {
            return .idlePaused
        }

        if driftScore >= 85 {
            return .overloaded
        }

        switch context {
        case .deepWork:
            return driftScore <= 35 ? .focused : .neutral
        case .assistedWork:
            return driftScore <= 45 ? .assistedDeepWork : .neutral
        case .development:
            return driftScore <= 45 ? .developmentLoop : .neutral
        case .research:
            return driftScore <= 40 ? .researchFlow : .neutral
        case .audioRegulation, .paused:
            return driftScore <= 30 ? .neutral : .passiveDrift
        case .generalBrowsing:
            return driftScore >= 55 ? .passiveDrift : .neutral
        case .passiveConsumption:
            return driftScore >= 70 ? .compulsiveDrift : .passiveDrift
        case .unknown:
            return driftScore >= 65 ? .passiveDrift : .unknown
        }
    }
}
