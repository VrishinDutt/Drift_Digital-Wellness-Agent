import Foundation

struct TelemetrySample: Equatable {
    let appName: String
    let bundleIdentifier: String?
    let windowTitle: String?
    let isIdle: Bool
    let timestamp: Date

    init(
        appName: String,
        bundleIdentifier: String? = nil,
        windowTitle: String? = nil,
        isIdle: Bool = false,
        timestamp: Date = Date()
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
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

    /// Native counterpart to the Python behavior engine.
    /// Keeps the pipeline deterministic, local, and lightweight:
    /// telemetry samples -> context -> drift score -> attention state -> intervention.
    func process(
        samples: [TelemetrySample],
        telemetryStatus: TelemetryStatus = .mocked
    ) -> AttentionSnapshot {
        let latest = samples.last ?? TelemetrySample(
            appName: "No active interaction",
            bundleIdentifier: nil,
            windowTitle: nil,
            isIdle: true,
            timestamp: Date()
        )

        let context: AttentionContext = latest.isIdle
            ? .paused
            : contextClassifier.classify(
                appName: latest.appName,
                windowTitle: latest.windowTitle
            )

        let driftScore = driftAnalyzer.score(
            samples: samples,
            context: context
        )

        let state = reasoningEngine.inferState(
            context: context,
            driftScore: driftScore,
            isIdle: latest.isIdle
        )

        let intervention = interventionEngine.intervention(
            for: state,
            context: context
        )

        return AttentionSnapshot(
            state: state,
            context: context,
            driftScore: driftScore,
            latestApp: latest.appName,
            latestTitle: latest.windowTitle,
            telemetryStatus: telemetryStatus,
            intervention: intervention,
            lastUpdated: Date()
        )
    }
}
