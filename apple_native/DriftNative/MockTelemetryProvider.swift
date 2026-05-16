import Foundation

struct MockTelemetryProvider {
    static let demoSnapshots: [AttentionSnapshot] = {
        let interventionEngine = InterventionEngine()
        let cognitiveRhythmLayer = CognitiveRhythmLayer()

        func snapshot(
            state: AttentionState,
            context: AttentionContext,
            driftScore: Int,
            latestApp: String,
            latestTitle: String? = nil
        ) -> AttentionSnapshot {
            let rhythmPlan = cognitiveRhythmLayer.plan(
                for: state,
                context: context,
                driftScore: driftScore
            )

            return AttentionSnapshot(
                state: state,
                context: context,
                driftScore: driftScore,
                latestApp: latestApp,
                latestTitle: latestTitle,
                telemetryStatus: .mocked,
                rhythmPlan: rhythmPlan,
                intervention: interventionEngine.intervention(
                    for: state,
                    context: context,
                    rhythmPlan: rhythmPlan
                )
            )
        }

        return [
            snapshot(
                state: .focused,
                context: .deepWork,
                driftScore: 15,
                latestApp: "Xcode",
                latestTitle: "DriftNative"
            ),
            snapshot(
                state: .assistedDeepWork,
                context: .development,
                driftScore: 30,
                latestApp: "Terminal + ChatGPT",
                latestTitle: "Build, inspect, refine"
            ),
            snapshot(
                state: .researchFlow,
                context: .research,
                driftScore: 25,
                latestApp: "Safari",
                latestTitle: "Technical reference"
            ),
            snapshot(
                state: .passiveDrift,
                context: .generalBrowsing,
                driftScore: 45,
                latestApp: "Safari",
                latestTitle: "General browsing"
            ),
            snapshot(
                state: .compulsiveDrift,
                context: .passiveConsumption,
                driftScore: 75,
                latestApp: "YouTube",
                latestTitle: "Passive feed loop"
            ),
            snapshot(
                state: .overloaded,
                context: .unknown,
                driftScore: 90,
                latestApp: "Rapid switching"
            ),
            snapshot(
                state: .idlePaused,
                context: .paused,
                driftScore: 5,
                latestApp: "None"
            )
        ]
    }()

    var count: Int {
        Self.demoSnapshots.count
    }

    func normalizedIndex(_ index: Int) -> Int {
        guard !Self.demoSnapshots.isEmpty else {
            return 0
        }

        return Self.demoSnapshots.indices.contains(index) ? index : 0
    }

    func nextIndex(after index: Int) -> Int {
        guard !Self.demoSnapshots.isEmpty else {
            return 0
        }

        return (normalizedIndex(index) + 1) % Self.demoSnapshots.count
    }

    func snapshot(at index: Int) -> AttentionSnapshot {
        Self.demoSnapshots[normalizedIndex(index)].refreshed()
    }
}

// Future native providers can layer in NSWorkspace foreground-app changes,
// AppKit activation notifications, user-granted window metadata, a menu bar
// agent, a floating HUD window, and local timeline storage. This mock provider
// intentionally adds no screenshots, keystroke logging, clipboard access, page
// scraping, message reading, or private screen capture.
extension AttentionSnapshot {
    func refreshed(at date: Date = Date()) -> AttentionSnapshot {
        AttentionSnapshot(
            id: UUID(),
            state: state,
            context: context,
            driftScore: driftScore,
            latestApp: latestApp,
            latestTitle: latestTitle,
            telemetryStatus: telemetryStatus,
            rhythmPlan: rhythmPlan,
            intervention: intervention,
            lastUpdated: date
        )
    }
}
