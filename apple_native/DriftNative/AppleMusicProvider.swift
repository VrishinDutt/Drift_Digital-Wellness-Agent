import Foundation
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
            return "Not Enabled"
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .unavailable:
            return "Unavailable"
        }
    }

    var calmCopy: String? {
        switch self {
        case .denied:
            return "Apple Music is optional. Drift still works locally."
        case .restricted:
            return "Apple Music is optional and can stay off."
        case .unavailable:
            return "Apple Music support is unavailable on this device."
        case .notDetermined, .authorized:
            return nil
        }
    }
}

@MainActor
final class AppleMusicProvider {
    var currentAuthorizationState: AppleMusicAuthorizationState {
        Self.resolveCurrentAuthorizationState()
    }

    func requestAuthorization() async -> AppleMusicAuthorizationState {
        #if canImport(MusicKit)
        let status = await MusicAuthorization.request()
        return Self.map(status)
        #else
        return .unavailable
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
