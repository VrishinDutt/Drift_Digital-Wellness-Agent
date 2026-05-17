import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(MusicKit)
import MusicKit
#endif

enum AppleMusicAuthorizationState: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable

    var displayName: String {
        switch self {
        case .notDetermined:
            return "Not Connected"
        case .authorized:
            return "Connected"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .unavailable:
            return "Unavailable"
        }
    }
}

enum AppleMusicSubscriptionStatus: Equatable {
    case notChecked
    case available
    case unknown

    var displayName: String {
        switch self {
        case .notChecked:
            return "Not checked"
        case .available:
            return "Available"
        case .unknown:
            return "Unknown"
        }
    }
}

@MainActor
final class AppleMusicProvider {
    private(set) var isAvailable: Bool
    private(set) var authorizationState: AppleMusicAuthorizationState
    private(set) var lastErrorMessage: String?
    private(set) var subscriptionStatus: AppleMusicSubscriptionStatus = .notChecked

    init() {
        self.isAvailable = Self.isMusicKitAvailable
        self.authorizationState = .unavailable
        refreshAuthorizationState()
    }

    var isAuthorized: Bool {
        authorizationState == .authorized
    }

    var statusLabel: String {
        guard isAvailable else {
            return "Unavailable"
        }

        switch authorizationState {
        case .notDetermined, .denied:
            return "Not Connected"
        case .authorized:
            return "Connected"
        case .restricted, .unavailable:
            return "Unavailable"
        }
    }

    var detailMessage: String {
        guard isAvailable else {
            return "Apple Music support is not available in this environment. Local cues remain available."
        }

        switch authorizationState {
        case .notDetermined:
            return "Connect Apple Music only if you want future music-aware rhythm support. Drift works locally without it."
        case .authorized:
            return "Music access is available. Drift will keep local soundscapes as the default and only use Apple Music when you choose."
        case .denied:
            return "Apple Music is optional. Drift still works locally with offline soundscape cues."
        case .restricted, .unavailable:
            return "Apple Music support is not available in this environment. Local cues remain available."
        }
    }

    var connectionCapabilityLabel: String {
        isAvailable && authorizationState != .restricted && authorizationState != .unavailable
            ? "Available"
            : "Unavailable"
    }

    var playbackStatusLabel: String {
        "Planned"
    }

    var localCuesStatusLabel: String {
        "Available"
    }

    var permissionStatusLabel: String? {
        switch authorizationState {
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        default:
            return nil
        }
    }

    /// Reads the current MusicKit authorization status without showing a prompt.
    @discardableResult
    func refreshAuthorizationState() -> AppleMusicAuthorizationState {
        isAvailable = Self.isMusicKitAvailable

        guard isAvailable else {
            authorizationState = .unavailable
            subscriptionStatus = .notChecked
            lastErrorMessage = nil
            return authorizationState
        }

        authorizationState = Self.resolveCurrentAuthorizationState()

        if !isAuthorized {
            subscriptionStatus = .notChecked
            lastErrorMessage = nil
        }

        return authorizationState
    }

    /// Checks status and future playback capability without requesting permission.
    @discardableResult
    func refreshConnectionState() async -> AppleMusicAuthorizationState {
        refreshAuthorizationState()
        await refreshPlaybackCapabilityIfAuthorized()
        return authorizationState
    }

    /// Call only from the user-initiated Enable Apple Music action. This is the
    /// only provider method that can show the macOS Apple Music permission prompt.
    @discardableResult
    func requestAuthorization() async -> AppleMusicAuthorizationState {
        refreshAuthorizationState()

        guard isAvailable else {
            authorizationState = .unavailable
            lastErrorMessage = "Apple Music is unavailable. Drift still works locally."
            return authorizationState
        }

        guard authorizationState == .notDetermined else {
            await refreshPlaybackCapabilityIfAuthorized()
            return authorizationState
        }

        #if canImport(MusicKit)
        _ = await MusicAuthorization.request()
        authorizationState = Self.resolveCurrentAuthorizationState()
        #else
        authorizationState = .unavailable
        #endif

        await refreshPlaybackCapabilityIfAuthorized()
        return authorizationState
    }

    /// User-initiated handoff to the Music app. This does not start playback,
    /// read a library, inspect listening history, or manipulate Apple Music content.
    @discardableResult
    func openMusicApp() async -> Bool {
        refreshAuthorizationState()

        guard isAuthorized else {
            lastErrorMessage = "Connect Apple Music before opening Music from Drift."
            return false
        }

        #if canImport(AppKit)
        guard let musicURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Music") else {
            lastErrorMessage = "Music app could not be found. Drift still works locally."
            return false
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.promptsUserIfNeeded = true

        let didOpen = await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(at: musicURL, configuration: configuration) { _, error in
                continuation.resume(returning: error == nil)
            }
        }

        lastErrorMessage = didOpen ? nil : "Music app could not be opened. Drift still works locally."
        return didOpen
        #else
        lastErrorMessage = "Music app handoff is unavailable in this build. Drift still works locally."
        return false
        #endif
    }

    private func refreshPlaybackCapabilityIfAuthorized() async {
        guard isAvailable, isAuthorized else {
            subscriptionStatus = .notChecked
            return
        }

        #if canImport(MusicKit)
        do {
            let subscription = try await MusicSubscription.current
            subscriptionStatus = subscription.canPlayCatalogContent ? .available : .unknown
            lastErrorMessage = nil
        } catch {
            subscriptionStatus = .unknown
            lastErrorMessage = nil
        }
        #else
        subscriptionStatus = .notChecked
        #endif
    }

    private static var isMusicKitAvailable: Bool {
        #if canImport(MusicKit)
        return true
        #else
        return false
        #endif
    }

    private static func resolveCurrentAuthorizationState() -> AppleMusicAuthorizationState {
        #if canImport(MusicKit)
        return map(MusicAuthorization.currentStatus)
        #else
        return .unavailable
        #endif
    }

    #if canImport(MusicKit)
    private static func map(_ status: MusicAuthorization.Status) -> AppleMusicAuthorizationState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .unavailable
        }
    }
    #endif
}
