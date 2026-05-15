import Combine
import Foundation

@MainActor
final class HUDViewModel: ObservableObject {
    @Published var snapshot: AttentionSnapshot
    @Published private(set) var isAutoCycleEnabled = false

    private static let mockCycleInterval: TimeInterval = 4

    private let telemetryProvider: MockTelemetryProvider
    private var currentIndex: Int
    private var mockCycleTimer: Timer?

    convenience init(initialIndex: Int = 0) {
        self.init(
            telemetryProvider: MockTelemetryProvider(),
            initialIndex: initialIndex
        )
    }

    init(telemetryProvider: MockTelemetryProvider, initialIndex: Int = 0) {
        self.telemetryProvider = telemetryProvider
        let safeIndex = telemetryProvider.normalizedIndex(initialIndex)
        self.currentIndex = safeIndex
        self.snapshot = telemetryProvider.snapshot(at: safeIndex)
    }

    func advanceSnapshot() {
        currentIndex = telemetryProvider.nextIndex(after: currentIndex)
        snapshot = telemetryProvider.snapshot(at: currentIndex)
    }

    func startMockCycle() {
        guard mockCycleTimer == nil else {
            isAutoCycleEnabled = true
            return
        }

        isAutoCycleEnabled = true
        mockCycleTimer = Timer.scheduledTimer(withTimeInterval: Self.mockCycleInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.advanceSnapshot()
            }
        }
    }

    func stopMockCycle() {
        mockCycleTimer?.invalidate()
        mockCycleTimer = nil
        isAutoCycleEnabled = false
    }

    deinit {
        mockCycleTimer?.invalidate()
    }
}
