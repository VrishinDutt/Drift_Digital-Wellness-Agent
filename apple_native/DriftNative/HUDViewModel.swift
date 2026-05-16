import Combine
import Foundation

enum TelemetryMode: String, CaseIterable, Identifiable {
    case mock
    case liveApp

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .mock:
            return "Mock"
        case .liveApp:
            return "Live App"
        }
    }
}

enum BreathingPhase: String {
    case inhale = "Inhale"
    case exhale = "Exhale"
}

@MainActor
final class HUDViewModel: ObservableObject {
    @Published var snapshot: AttentionSnapshot
    @Published private(set) var telemetryMode: TelemetryMode = .mock
    @Published private(set) var isAutoCycleEnabled = false
    @Published private(set) var recentSamples: [TelemetrySample] = []
    @Published private(set) var selectedIntention: String?
    @Published private(set) var isBreathingResetActive = false
    @Published private(set) var breathingPhase: BreathingPhase = .inhale
    @Published private(set) var diagnosticEntries: [DriftLogEntry] = []
    @Published private(set) var soundscapePlaybackState: SoundscapePlaybackState = .idle
    @Published private(set) var currentSoundscapeMode: SoundscapeMode = .none
    @Published private(set) var appleMusicAuthorizationState: AppleMusicAuthorizationState

    private static let mockCycleInterval: TimeInterval = 4
    private static let livePollingInterval: TimeInterval = 2.5
    private static let breathingPhaseInterval: TimeInterval = 2.8
    private static let duplicateSampleWindow: TimeInterval = 7

    private let mockTelemetryProvider: MockTelemetryProvider
    private let nativeTelemetryProvider: NativeTelemetryProvider
    private let behaviorEngine: BehaviorEngine
    private let soundscapePlayer: LocalSoundscapePlayer
    private let appleMusicProvider: AppleMusicProvider
    private let logger: DriftLogger
    private let maxSamples = 20
    private var currentIndex: Int
    private var mockCycleTimer: Timer?
    private var liveTelemetryTimer: Timer?
    private var breathingTimer: Timer?
    private var breathingStepsRemaining = 0

    convenience init(initialIndex: Int = 0) {
        self.init(
            mockTelemetryProvider: MockTelemetryProvider(),
            nativeTelemetryProvider: NativeTelemetryProvider(),
            behaviorEngine: BehaviorEngine(),
            soundscapePlayer: LocalSoundscapePlayer(),
            appleMusicProvider: AppleMusicProvider(),
            logger: DriftLogger(),
            initialIndex: initialIndex
        )
    }

    init(
        mockTelemetryProvider: MockTelemetryProvider,
        nativeTelemetryProvider: NativeTelemetryProvider,
        behaviorEngine: BehaviorEngine,
        soundscapePlayer: LocalSoundscapePlayer,
        appleMusicProvider: AppleMusicProvider,
        logger: DriftLogger,
        initialIndex: Int = 0
    ) {
        self.mockTelemetryProvider = mockTelemetryProvider
        self.nativeTelemetryProvider = nativeTelemetryProvider
        self.behaviorEngine = behaviorEngine
        self.soundscapePlayer = soundscapePlayer
        self.appleMusicProvider = appleMusicProvider
        self.logger = logger
        self.appleMusicAuthorizationState = appleMusicProvider.currentAuthorizationState
        let safeIndex = mockTelemetryProvider.normalizedIndex(initialIndex)
        self.currentIndex = safeIndex
        self.snapshot = mockTelemetryProvider.snapshot(at: safeIndex)
        self.recentSamples = [Self.sample(from: snapshot)]
        log(.snapshot, "Initialized mock snapshot: \(snapshot.state.displayName)")
    }

    var recentSignal: [TelemetrySample] {
        Array(recentSamples.suffix(8).reversed())
    }

    var bufferSizeDescription: String {
        "\(recentSamples.count)/\(maxSamples)"
    }

    var readingExplanation: String {
        switch snapshot.state {
        case .focused:
            return "The current signal looks steady and task-oriented."
        case .assistedDeepWork:
            return "The active app pattern looks like supported work, not drift."
        case .developmentLoop:
            return "Recent app movement fits an intentional development loop."
        case .researchFlow:
            return "The visible signal points toward focused research."
        case .neutral:
            if snapshot.context == .generalBrowsing {
                return "Only the active browser app is visible, so Drift keeps this reading neutral."
            }
            return "The signal is mixed, so Drift stays quiet."
        case .passiveDrift:
            return "Recent context suggests a softer attention check may help."
        case .compulsiveDrift:
            return "The signal suggests repeated passive attention, so Drift offers a light pause."
        case .overloaded:
            return "Rapid or unclear context changes can benefit from a short reset."
        case .idlePaused:
            return "The system appears paused, so there is nothing to adjust."
        case .unknown:
            return "There is not enough context yet for a confident reading."
        }
    }

    var interventionStatus: String {
        switch snapshot.intervention.kind {
        case .none:
            return "Drift is staying quiet."
        case .reflectivePrompt:
            return "Optional intention cue."
        case .breathingReset:
            return "Optional breathing cue."
        case .softPause:
            return "Soft pause available."
        case .rhythmTransitionSuggestion:
            return "Optional \(snapshot.rhythmPlan.displayName)."
        }
    }

    var rhythmStatus: String {
        if snapshot.rhythmPlan.shouldSurface {
            return snapshot.rhythmPlan.interventionMessage
        }

        return snapshot.rhythmPlan.guidance
    }

    var hasSoundscapeSuggestion: Bool {
        snapshot.rhythmPlan.hasSoundscapeSuggestion
    }

    var suggestedSoundscapeMode: SoundscapeMode {
        snapshot.rhythmPlan.soundscapeMode
    }

    var suggestedSoundscapeAssetName: String {
        suggestedSoundscapeMode.defaultLocalAssetName ?? "No local asset"
    }

    var isSuggestedSoundscapeAvailable: Bool {
        guard hasSoundscapeSuggestion else {
            return false
        }

        return soundscapePlayer.isAssetAvailable(for: suggestedSoundscapeMode)
    }

    var suggestedSoundscapeAvailabilityMessage: String? {
        guard hasSoundscapeSuggestion, !isSuggestedSoundscapeAvailable else {
            return nil
        }

        return "Local cue unavailable for this rhythm."
    }

    var soundscapePlaybackStatus: String {
        soundscapePlaybackState.displayName
    }

    var appleMusicAuthorizationStatus: String {
        appleMusicAuthorizationState.displayName
    }

    var appleMusicCalmCopy: String? {
        appleMusicAuthorizationState.calmCopy
    }

    var compactInterventionLine: String {
        if let selectedIntention {
            return "Intention set: \(selectedIntention)"
        }

        if isBreathingResetActive {
            return breathingPhase.rawValue
        }

        return snapshot.intervention.message
    }

    func advanceSnapshot() {
        guard telemetryMode == .mock else {
            pollLiveTelemetry()
            return
        }

        currentIndex = mockTelemetryProvider.nextIndex(after: currentIndex)
        setMockSnapshot(at: currentIndex)
    }

    func setTelemetryMode(_ mode: TelemetryMode) {
        guard telemetryMode != mode else {
            return
        }

        telemetryMode = mode
        log(.mode, "Mode changed: \(mode.displayName)")

        switch mode {
        case .mock:
            stopLiveTelemetry()
            setMockSnapshot(at: currentIndex)
        case .liveApp:
            stopMockCycle()
            startLiveTelemetry()
        }
    }

    func startMockCycle() {
        guard telemetryMode == .mock else {
            return
        }

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

    func stopAllTimers() {
        stopMockCycle()
        stopLiveTelemetry()
        dismissBreathingReset()
        stopSoundscape()
    }

    func selectInterventionChoice(_ choice: String) {
        guard snapshot.intervention.choices.contains(choice) else {
            return
        }

        selectedIntention = choice
        dismissBreathingReset()
        log(.intervention, "Intention set: \(choice)")
    }

    func startBreathingReset() {
        guard snapshot.intervention.kind == .breathingReset else {
            return
        }

        breathingTimer?.invalidate()
        selectedIntention = nil
        isBreathingResetActive = true
        breathingPhase = .inhale
        breathingStepsRemaining = 4
        log(.intervention, "Breathing cue started")

        breathingTimer = Timer.scheduledTimer(withTimeInterval: Self.breathingPhaseInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.advanceBreathingCue()
            }
        }
    }

    func dismissBreathingReset() {
        breathingTimer?.invalidate()
        breathingTimer = nil
        isBreathingResetActive = false
        breathingPhase = .inhale
        breathingStepsRemaining = 0
    }

    func playSuggestedSoundscape() {
        guard hasSoundscapeSuggestion else {
            return
        }

        applySoundscapeState(
            soundscapePlayer.play(suggestedSoundscapeMode, logger: logger),
            logMessage: "User started local cue: \(suggestedSoundscapeMode.displayName)"
        )
    }

    func playBreathingCue() {
        applySoundscapeState(
            soundscapePlayer.play(.breathingCue, logger: logger),
            logMessage: "User tested local breathing cue"
        )
    }

    func pauseSoundscape() {
        applySoundscapeState(
            soundscapePlayer.pause(),
            logMessage: "User paused local cue"
        )
    }

    func stopSoundscape() {
        applySoundscapeState(
            soundscapePlayer.stop(),
            logMessage: "User stopped local cue"
        )
    }

    func requestAppleMusicAuthorization() async {
        let state = await appleMusicProvider.requestAuthorization()
        appleMusicAuthorizationState = state
        log(.soundscape, "Apple Music authorization: \(state.displayName)")
    }

    deinit {
        mockCycleTimer?.invalidate()
        liveTelemetryTimer?.invalidate()
        breathingTimer?.invalidate()
    }

    private func startLiveTelemetry() {
        pollLiveTelemetry()

        guard liveTelemetryTimer == nil else {
            return
        }

        liveTelemetryTimer = Timer.scheduledTimer(withTimeInterval: Self.livePollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollLiveTelemetry()
            }
        }
    }

    private func stopLiveTelemetry() {
        liveTelemetryTimer?.invalidate()
        liveTelemetryTimer = nil
    }

    private func pollLiveTelemetry() {
        let sample = nativeTelemetryProvider.currentSample()

        let status: TelemetryStatus = sample.appName == NativeTelemetryProvider.unavailableAppName
            ? .unavailable
            : .live

        if status == .unavailable {
            log(.telemetry, "Telemetry unavailable")
        } else {
            log(.telemetry, "Active app sampled: \(sample.appName)")
        }

        let didAppend = appendSample(sample)
        guard didAppend else {
            return
        }

        applySnapshot(
            behaviorEngine.process(
                samples: recentSamples,
                telemetryStatus: status
            )
        )
    }

    private func setMockSnapshot(at index: Int) {
        applySnapshot(mockTelemetryProvider.snapshot(at: index))
        _ = appendSample(Self.sample(from: snapshot))
    }

    @discardableResult
    private func appendSample(_ sample: TelemetrySample) -> Bool {
        if shouldSkipDuplicate(sample) {
            log(.buffer, "Skipped duplicate app sample: \(sample.appName)")
            return false
        }

        recentSamples.append(sample)

        if recentSamples.count > maxSamples {
            recentSamples.removeFirst(recentSamples.count - maxSamples)
            log(.buffer, "Sample buffer trimmed to \(maxSamples)")
        }

        return true
    }

    private static func sample(from snapshot: AttentionSnapshot) -> TelemetrySample {
        TelemetrySample(
            appName: snapshot.latestApp,
            windowTitle: snapshot.latestTitle,
            isIdle: snapshot.state == .idlePaused,
            timestamp: snapshot.lastUpdated
        )
    }

    private func applySnapshot(_ newSnapshot: AttentionSnapshot) {
        let previousIntervention = snapshot.intervention
        let previousRhythmPlan = snapshot.rhythmPlan
        snapshot = newSnapshot
        log(
            .snapshot,
            "Snapshot updated: \(newSnapshot.state.displayName), drift \(newSnapshot.driftScore)"
        )

        if newSnapshot.rhythmPlan != previousRhythmPlan {
            log(.rhythm, "Rhythm cue: \(newSnapshot.rhythmPlan.displayName)")
        }

        if newSnapshot.intervention != previousIntervention {
            resetInterventionUI()
        }
    }

    private func resetInterventionUI() {
        selectedIntention = nil
        dismissBreathingReset()
    }

    private func applySoundscapeState(
        _ state: SoundscapePlaybackState,
        logMessage: String
    ) {
        soundscapePlaybackState = state
        currentSoundscapeMode = soundscapePlayer.currentMode

        switch state {
        case .idle:
            log(.soundscape, logMessage)
        case .playing:
            log(.soundscape, logMessage)
        case .paused:
            log(.soundscape, logMessage)
        case .unavailable(let mode):
            log(.soundscape, "Soundscape asset unavailable: \(mode.defaultLocalAssetName ?? "No local asset")")
        case .failed(let mode, let message):
            log(.soundscape, "\(mode.displayName): \(message)")
        }
    }

    private func advanceBreathingCue() {
        guard breathingStepsRemaining > 0 else {
            dismissBreathingReset()
            return
        }

        breathingPhase = breathingPhase == .inhale ? .exhale : .inhale
        breathingStepsRemaining -= 1

        if breathingStepsRemaining == 0 {
            breathingTimer?.invalidate()
            breathingTimer = nil
            log(.intervention, "Breathing cue completed")
        }
    }

    private func shouldSkipDuplicate(_ sample: TelemetrySample) -> Bool {
        guard let latest = recentSamples.last else {
            return false
        }

        let isSameApp = latest.appName.caseInsensitiveCompare(sample.appName) == .orderedSame
        let isSameBundle = latest.bundleIdentifier == sample.bundleIdentifier
        let interval = sample.timestamp.timeIntervalSince(latest.timestamp)

        return isSameApp && isSameBundle && interval < Self.duplicateSampleWindow
    }

    private func log(_ category: DriftLogCategory, _ message: String) {
        logger.log(category, message)
        diagnosticEntries = logger.recent(limit: 6)
    }
}
