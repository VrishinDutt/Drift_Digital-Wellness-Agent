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

enum BreathingPhase: CaseIterable, Equatable {
    case inhale
    case hold
    case exhale
    case rest

    var displayText: String {
        switch self {
        case .inhale:
            return "Breathe in"
        case .hold:
            return "Hold"
        case .exhale:
            return "Breathe out"
        case .rest:
            return "Rest"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .inhale:
            return 4
        case .hold:
            return 2
        case .exhale:
            return 6
        case .rest:
            return 2
        }
    }

    var next: BreathingPhase {
        switch self {
        case .inhale:
            return .hold
        case .hold:
            return .exhale
        case .exhale:
            return .rest
        case .rest:
            return .inhale
        }
    }
}

private enum BreathingOrbSource {
    case suggested
    case manual
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
    @Published private(set) var appleMusicAuthorizationState: AppleMusicAuthorizationState = .unavailable
    @Published private(set) var appleMusicStatusLabel = AppleMusicAuthorizationState.unavailable.displayName
    @Published private(set) var appleMusicDetailMessage = "Apple Music support is not available in this environment. Local cues remain available."
    @Published private(set) var isAppleMusicConnected = false
    @Published private(set) var appleMusicIsAvailable = false
    @Published private(set) var appleMusicLastErrorMessage: String?
    @Published private(set) var appleMusicConnectionCapabilityLabel = "Unavailable"
    @Published private(set) var appleMusicPlaybackStatusLabel = "Planned"
    @Published private(set) var appleMusicLocalCuesStatusLabel = "Available"
    @Published private(set) var appleMusicSubscriptionStatusLabel = AppleMusicSubscriptionStatus.notChecked.displayName
    @Published private(set) var appleMusicPermissionStatusLabel: String?
    @Published private(set) var recommendedAmbiencePreset: VisualAmbiencePreset
    @Published private(set) var selectedAmbiencePreset: VisualAmbiencePreset?
    @Published private(set) var ambienceRecommendationReason: String
    @Published private(set) var ambienceApplyMessage: String?

    private static let mockCycleInterval: TimeInterval = 4
    private static let livePollingInterval: TimeInterval = 2.5
    private static let duplicateSampleWindow: TimeInterval = 7

    private let mockTelemetryProvider: MockTelemetryProvider
    private let nativeTelemetryProvider: NativeTelemetryProvider
    private let behaviorEngine: BehaviorEngine
    private let soundscapePlayer: LocalSoundscapePlayer
    private let appleMusicProvider: AppleMusicProvider
    private let visualAmbienceEngine: VisualAmbienceEngine
    private let visualAmbienceManager: VisualAmbienceManager
    private let logger: DriftLogger
    private let maxSamples = 20
    private var currentIndex: Int
    private var mockCycleTimer: Timer?
    private var liveTelemetryTimer: Timer?
    private var breathingTimer: Timer?
    private var breathingOrbSource: BreathingOrbSource?
    private var dismissedBreathingSuggestionID: UUID?

    convenience init(initialIndex: Int = 0) {
        self.init(
            mockTelemetryProvider: MockTelemetryProvider(),
            nativeTelemetryProvider: NativeTelemetryProvider(),
            behaviorEngine: BehaviorEngine(),
            soundscapePlayer: LocalSoundscapePlayer(),
            appleMusicProvider: AppleMusicProvider(),
            visualAmbienceEngine: VisualAmbienceEngine(),
            visualAmbienceManager: VisualAmbienceManager(),
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
        visualAmbienceEngine: VisualAmbienceEngine,
        visualAmbienceManager: VisualAmbienceManager,
        logger: DriftLogger,
        initialIndex: Int = 0
    ) {
        self.mockTelemetryProvider = mockTelemetryProvider
        self.nativeTelemetryProvider = nativeTelemetryProvider
        self.behaviorEngine = behaviorEngine
        self.soundscapePlayer = soundscapePlayer
        self.appleMusicProvider = appleMusicProvider
        self.visualAmbienceEngine = visualAmbienceEngine
        self.visualAmbienceManager = visualAmbienceManager
        self.logger = logger
        let safeIndex = mockTelemetryProvider.normalizedIndex(initialIndex)
        let initialSnapshot = mockTelemetryProvider.snapshot(at: safeIndex)
        let initialAmbienceRecommendation = visualAmbienceEngine.recommendation(for: initialSnapshot)
        self.currentIndex = safeIndex
        self.snapshot = initialSnapshot
        self.recommendedAmbiencePreset = initialAmbienceRecommendation.preset
        self.ambienceRecommendationReason = initialAmbienceRecommendation.rationale
        self.ambienceApplyMessage = visualAmbienceManager.assetUnavailableMessage(
            for: initialAmbienceRecommendation.preset
        )
        self.recentSamples = [Self.sample(from: snapshot)]
        syncAppleMusicState(refreshAuthorization: true)
        log(.snapshot, "Initialized mock snapshot: \(snapshot.state.displayName)")
        log(.ambience, "Ambience suggested: \(recommendedAmbiencePreset.title)")
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

    var visibleAmbiencePresets: [VisualAmbiencePreset] {
        guard let selectedAmbiencePreset else {
            return visualAmbienceEngine.visiblePresets(for: snapshot)
        }

        return uniqueAmbiencePresets(
            [selectedAmbiencePreset] + visualAmbienceEngine.visiblePresets(for: snapshot)
        )
    }

    var ambienceStatusMessage: String? {
        ambienceApplyMessage ?? visualAmbienceManager.assetUnavailableMessage(for: ambiencePreviewPreset)
    }

    var canApplyAmbience: Bool {
        selectedAmbiencePreset != nil
    }

    private var ambiencePreviewPreset: VisualAmbiencePreset {
        selectedAmbiencePreset ?? recommendedAmbiencePreset
    }

    var appleMusicAuthorizationStatus: String {
        appleMusicStatusLabel
    }

    var appleMusicAvailabilityStatus: String {
        appleMusicIsAvailable ? "Available" : "Unavailable"
    }

    var canRequestAppleMusicAuthorization: Bool {
        appleMusicIsAvailable && appleMusicAuthorizationState == .notDetermined
    }

    var canOpenMusicApp: Bool {
        isAppleMusicConnected
    }

    var compactInterventionLine: String {
        if let selectedIntention {
            return "Intention set: \(selectedIntention)"
        }

        if isBreathingResetActive {
            return "Breathing reset"
        }

        return snapshot.intervention.message
    }

    var shouldSuggestBreathingOrb: Bool {
        snapshot.intervention.kind == .breathingReset || snapshot.state == .overloaded
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
        closeBreathingOrb(shouldLog: false)
        stopSoundscape()
    }

    func selectInterventionChoice(_ choice: String) {
        guard snapshot.intervention.choices.contains(choice) else {
            return
        }

        selectedIntention = choice
        closeBreathingOrb(shouldLog: false)
        log(.intervention, "Intention set: \(choice)")
    }

    func startBreathingReset() {
        openBreathingOrb(source: .manual)
    }

    func openSuggestedBreathingOrbIfNeeded() {
        guard shouldSuggestBreathingOrb else {
            return
        }

        guard dismissedBreathingSuggestionID != snapshot.id else {
            return
        }

        guard !isBreathingResetActive else {
            return
        }

        openBreathingOrb(source: .suggested)
    }

    func dismissBreathingReset() {
        closeBreathingOrb(shouldLog: true, markCurrentSuggestionDismissed: true)
    }

    private func openBreathingOrb(source: BreathingOrbSource) {
        breathingTimer?.invalidate()
        selectedIntention = nil
        isBreathingResetActive = true
        breathingOrbSource = source
        breathingPhase = .inhale
        log(.intervention, "Breathing orb opened")
        scheduleNextBreathingPhase()
    }

    private func scheduleNextBreathingPhase() {
        breathingTimer?.invalidate()
        breathingTimer = Timer.scheduledTimer(withTimeInterval: breathingPhase.duration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.advanceBreathingCue()
            }
        }
    }

    private func closeBreathingOrb(
        shouldLog: Bool,
        markCurrentSuggestionDismissed: Bool = false
    ) {
        let wasActive = isBreathingResetActive
        breathingTimer?.invalidate()
        breathingTimer = nil
        isBreathingResetActive = false
        breathingOrbSource = nil
        breathingPhase = .inhale

        if markCurrentSuggestionDismissed, shouldSuggestBreathingOrb {
            dismissedBreathingSuggestionID = snapshot.id
        }

        if shouldLog, wasActive {
            log(.intervention, "Breathing orb dismissed")
        }
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

    func selectAmbiencePreset(_ preset: VisualAmbiencePreset) {
        selectedAmbiencePreset = preset
        ambienceApplyMessage = visualAmbienceManager.assetUnavailableMessage(for: preset)
        log(.ambience, "Ambience selected: \(preset.title)")
    }

    func applyAmbience() {
        guard let selectedAmbiencePreset else {
            return
        }

        log(.ambience, "Ambience apply requested: \(selectedAmbiencePreset.title)")
        let result = visualAmbienceManager.applyPreset(selectedAmbiencePreset)
        ambienceApplyMessage = result.message

        switch result {
        case .applied:
            log(.ambience, "Ambience applied: \(selectedAmbiencePreset.title)")
        case .previewOnly:
            log(.ambience, "Ambience preview only: \(selectedAmbiencePreset.title)")
        case .failed:
            log(.ambience, "Ambience apply failed: \(selectedAmbiencePreset.title)")
        }
    }

    func requestAppleMusicAuthorization() async {
        guard canRequestAppleMusicAuthorization else {
            await checkAppleMusicStatus()
            return
        }

        let state = await appleMusicProvider.requestAuthorization()
        syncAppleMusicState()
        log(.soundscape, "Apple Music authorization: \(state.displayName)")
    }

    func checkAppleMusicStatus() async {
        let state = await appleMusicProvider.refreshConnectionState()
        syncAppleMusicState()
        log(.soundscape, "Apple Music status checked: \(state.displayName)")
    }

    func openMusicApp() async {
        guard canOpenMusicApp else {
            await checkAppleMusicStatus()
            return
        }

        let didOpen = await appleMusicProvider.openMusicApp()
        syncAppleMusicState()

        if didOpen {
            log(.soundscape, "User opened Music app")
        } else {
            log(.soundscape, "Music app handoff unavailable")
        }
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
        let previousAmbiencePreset = recommendedAmbiencePreset
        snapshot = newSnapshot
        updateAmbienceRecommendation(for: newSnapshot, previousPreset: previousAmbiencePreset)
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

    private func updateAmbienceRecommendation(
        for snapshot: AttentionSnapshot,
        previousPreset: VisualAmbiencePreset
    ) {
        let recommendation = visualAmbienceEngine.recommendation(for: snapshot)
        recommendedAmbiencePreset = recommendation.preset
        ambienceRecommendationReason = recommendation.rationale

        if selectedAmbiencePreset == nil {
            ambienceApplyMessage = visualAmbienceManager.assetUnavailableMessage(for: recommendation.preset)
        }

        if recommendation.preset != previousPreset {
            log(.ambience, "Ambience suggested: \(recommendation.preset.title)")
        }
    }

    private func resetInterventionUI() {
        selectedIntention = nil

        if breathingOrbSource == .suggested, !shouldSuggestBreathingOrb {
            closeBreathingOrb(shouldLog: false)
        }
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

    private func syncAppleMusicState(refreshAuthorization: Bool = false) {
        if refreshAuthorization {
            appleMusicProvider.refreshAuthorizationState()
        }

        appleMusicAuthorizationState = appleMusicProvider.authorizationState
        appleMusicStatusLabel = appleMusicProvider.statusLabel
        appleMusicDetailMessage = appleMusicProvider.detailMessage
        isAppleMusicConnected = appleMusicProvider.isAuthorized
        appleMusicIsAvailable = appleMusicProvider.isAvailable
        appleMusicLastErrorMessage = appleMusicProvider.lastErrorMessage
        appleMusicConnectionCapabilityLabel = appleMusicProvider.connectionCapabilityLabel
        appleMusicPlaybackStatusLabel = appleMusicProvider.playbackStatusLabel
        appleMusicLocalCuesStatusLabel = appleMusicProvider.localCuesStatusLabel
        appleMusicSubscriptionStatusLabel = appleMusicProvider.subscriptionStatus.displayName
        appleMusicPermissionStatusLabel = appleMusicProvider.permissionStatusLabel
    }

    private func advanceBreathingCue() {
        guard isBreathingResetActive else {
            closeBreathingOrb(shouldLog: false)
            return
        }

        let completedCycle = breathingPhase == .rest
        breathingPhase = breathingPhase.next

        if completedCycle {
            log(.intervention, "Breathing cycle completed")
        }

        scheduleNextBreathingPhase()
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

    private func uniqueAmbiencePresets(_ presets: [VisualAmbiencePreset]) -> [VisualAmbiencePreset] {
        var seen: [String] = []
        var unique: [VisualAmbiencePreset] = []

        for preset in presets where !seen.contains(preset.id) {
            seen.append(preset.id)
            unique.append(preset)

            if unique.count == 4 {
                break
            }
        }

        return unique
    }

    private func log(_ category: DriftLogCategory, _ message: String) {
        logger.log(category, message)
        diagnosticEntries = logger.recent(limit: 6)
    }
}
