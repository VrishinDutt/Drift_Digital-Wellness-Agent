import Foundation

struct TelemetrySample: Equatable {
    let appName: String
    let windowTitle: String?
    let isIdle: Bool
    let timestamp: Date

    init(
        appName: String,
        windowTitle: String? = nil,
        isIdle: Bool = false,
        timestamp: Date = Date()
    ) {
        self.appName = appName
        self.windowTitle = windowTitle
        self.isIdle = isIdle
        self.timestamp = timestamp
    }
}

struct BehaviorEngine {
    var contextClassifier = ContextClassifier()
    var driftAnalyzer = DriftAnalyzer()
    var reasoningEngine = ReasoningEngine()
    var interventionEngine = InterventionEngine()

    /// Native counterpart to Python's `core.behavior_engine.process_behavior`.
    /// This is intentionally small for the scaffold: it demonstrates the pipeline
    /// shape without pretending to be a finished model.
    func process(samples: [TelemetrySample]) -> AttentionSnapshot {
        let latest = samples.last ?? TelemetrySample(
            appName: "No active interaction",
            windowTitle: nil,
            isIdle: true
        )

        let context = contextClassifier.classify(
            appName: latest.appName,
            windowTitle: latest.windowTitle
        )
        let driftScore = driftAnalyzer.score(samples: samples, context: context)
        let state = reasoningEngine.inferState(
            context: context,
            driftScore: driftScore,
            isIdle: latest.isIdle
        )
        let message = interventionEngine.message(for: state, context: context)

        return AttentionSnapshot(
            state: state,
            context: context,
            driftScore: driftScore,
            latestApp: latest.appName,
            latestTitle: latest.windowTitle,
            telemetryStatus: .mocked,
            interventionMessage: message,
            lastUpdated: Date()
        )
    }
}
