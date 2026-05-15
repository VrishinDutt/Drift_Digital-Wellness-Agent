import Combine
import Foundation

final class MockTelemetryProvider: ObservableObject {
    @Published private(set) var currentSnapshot: AttentionSnapshot

    private var currentIndex: Int

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
            latestTitle: "Development loop",
            telemetryStatus: .mocked,
            interventionMessage: "Assisted work looks steady."
        ),
        AttentionSnapshot(
            state: .focused,
            context: .research,
            driftScore: 25,
            latestApp: "Safari",
            latestTitle: "StackExchange / GitHub",
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
            latestApp: "YouTube / Reddit",
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
            context: .unknown,
            driftScore: 5,
            latestApp: "No active interaction",
            latestTitle: nil,
            telemetryStatus: .mocked,
            interventionMessage: "Quiet mode. Nothing needs attention."
        )
    ]

    init(initialIndex: Int = 0) {
        let safeIndex = Self.demoSnapshots.indices.contains(initialIndex) ? initialIndex : 0
        self.currentIndex = safeIndex
        self.currentSnapshot = Self.demoSnapshots[safeIndex].refreshed()
    }

    func advance() {
        currentIndex = (currentIndex + 1) % Self.demoSnapshots.count
        currentSnapshot = Self.demoSnapshots[currentIndex].refreshed()
    }
}

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
