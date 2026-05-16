import Foundation

struct AttentionSnapshot: Identifiable, Equatable {
    let id: UUID
    let state: AttentionState
    let context: AttentionContext
    let driftScore: Int
    let latestApp: String
    let latestTitle: String?
    let telemetryStatus: TelemetryStatus
    let rhythmPlan: CognitiveRhythmPlan
    let intervention: AttentionIntervention
    let lastUpdated: Date

    var interventionMessage: String {
        intervention.message
    }

    init(
        id: UUID = UUID(),
        state: AttentionState,
        context: AttentionContext,
        driftScore: Int,
        latestApp: String,
        latestTitle: String? = nil,
        telemetryStatus: TelemetryStatus,
        rhythmPlan: CognitiveRhythmPlan = .none,
        intervention: AttentionIntervention? = nil,
        interventionMessage: String? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.state = state
        self.context = context
        self.driftScore = max(0, min(driftScore, 100))
        self.latestApp = latestApp
        self.latestTitle = latestTitle
        self.telemetryStatus = telemetryStatus
        self.rhythmPlan = rhythmPlan
        self.intervention = intervention ?? AttentionIntervention(
            kind: .none,
            title: "No intervention needed",
            message: interventionMessage ?? AttentionIntervention.none.message,
            choices: [],
            tone: "quiet",
            shouldExpandWidget: false
        )
        self.lastUpdated = lastUpdated
    }
}

enum AttentionState: String, CaseIterable, Equatable {
    case focused
    case assistedDeepWork
    case developmentLoop
    case researchFlow
    case neutral
    case passiveDrift
    case compulsiveDrift
    case overloaded
    case idlePaused
    case unknown

    var displayName: String {
        switch self {
        case .focused:
            return "Focused"
        case .assistedDeepWork:
            return "Assisted Deep Work"
        case .developmentLoop:
            return "Development Loop"
        case .researchFlow:
            return "Research Flow"
        case .neutral:
            return "Neutral"
        case .passiveDrift:
            return "Passive Drift"
        case .compulsiveDrift:
            return "Compulsive Drift"
        case .overloaded:
            return "Overloaded"
        case .idlePaused:
            return "Idle / Paused"
        case .unknown:
            return "Unknown"
        }
    }
}

enum AttentionContext: String, CaseIterable, Equatable {
    case deepWork
    case assistedWork
    case development
    case research
    case generalBrowsing
    case passiveConsumption
    case audioRegulation
    case paused
    case unknown

    var displayName: String {
        switch self {
        case .deepWork:
            return "Deep Work"
        case .assistedWork:
            return "Assisted Work"
        case .development:
            return "Development Loop"
        case .research:
            return "Research"
        case .generalBrowsing:
            return "General Browsing"
        case .passiveConsumption:
            return "Passive Consumption"
        case .audioRegulation:
            return "Audio Regulation"
        case .paused:
            return "Paused"
        case .unknown:
            return "Unknown"
        }
    }
}

enum TelemetryStatus: String, CaseIterable, Equatable {
    case mocked
    case live
    case stale
    case unavailable

    var displayName: String {
        switch self {
        case .mocked:
            return "Mocked"
        case .live:
            return "Live"
        case .stale:
            return "Stale"
        case .unavailable:
            return "Unavailable"
        }
    }
}
