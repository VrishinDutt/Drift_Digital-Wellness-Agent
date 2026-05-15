import Foundation

struct MockTelemetryProvider {
    static let demoSnapshots: [AttentionSnapshot] = [
        AttentionSnapshot(
            state: .focused,
            context: .deepWork,
            driftScore: 15,
            latestApp: "Xcode",
            latestTitle: "DriftNative",
            telemetryStatus: .mocked,
            interventionMessage: "No intervention needed."
        ),
        AttentionSnapshot(
            state: .assistedDeepWork,
            context: .development,
            driftScore: 30,
            latestApp: "Terminal + ChatGPT",
            latestTitle: "Build, inspect, refine",
            telemetryStatus: .mocked,
            interventionMessage: "Assistance is supporting the work loop."
        ),
        AttentionSnapshot(
            state: .researchFlow,
            context: .research,
            driftScore: 25,
            latestApp: "Safari",
            latestTitle: "Technical reference",
            telemetryStatus: .mocked,
            interventionMessage: "Research flow looks clear."
        ),
        AttentionSnapshot(
            state: .passiveDrift,
            context: .generalBrowsing,
            driftScore: 45,
            latestApp: "Safari",
            latestTitle: "General browsing",
            telemetryStatus: .mocked,
            interventionMessage: "Slow the transition for a moment."
        ),
        AttentionSnapshot(
            state: .compulsiveDrift,
            context: .passiveConsumption,
            driftScore: 75,
            latestApp: "YouTube",
            latestTitle: "Passive feed loop",
            telemetryStatus: .mocked,
            interventionMessage: "Let the impulse settle briefly."
        ),
        AttentionSnapshot(
            state: .overloaded,
            context: .unknown,
            driftScore: 90,
            latestApp: "Rapid switching",
            latestTitle: nil,
            telemetryStatus: .mocked,
            interventionMessage: "A short reset may help restore clarity."
        ),
        AttentionSnapshot(
            state: .idlePaused,
            context: .paused,
            driftScore: 5,
            latestApp: "None",
            latestTitle: nil,
            telemetryStatus: .mocked,
            interventionMessage: "Quiet mode. Nothing needs attention."
        )
    ]

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
// AppKit activation notifications, user-granted AXUIElement window metadata,
// a menu bar agent, a floating HUD window, and local timeline storage. This
// mock provider intentionally adds no screenshots, keystroke logging, clipboard
// access, page scraping, message reading, or private screen capture.
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
            interventionMessage: interventionMessage,
            lastUpdated: date
        )
    }
}
