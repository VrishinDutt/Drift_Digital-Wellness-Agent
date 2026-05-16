import AVFoundation
import Foundation

enum SoundscapePlaybackState: Equatable {
    case idle
    case playing(SoundscapeMode)
    case paused(SoundscapeMode)
    case unavailable(SoundscapeMode)
    case failed(SoundscapeMode, String)

    var displayName: String {
        switch self {
        case .idle:
            return "No local soundscape is playing."
        case .playing(let mode):
            return "\(mode.displayName) is playing locally."
        case .paused(let mode):
            return "\(mode.displayName) is paused."
        case .unavailable:
            return "Local cue unavailable for this rhythm."
        case .failed(_, let message):
            return message
        }
    }

    var isActive: Bool {
        switch self {
        case .playing, .paused:
            return true
        case .idle, .unavailable, .failed:
            return false
        }
    }
}

@MainActor
final class LocalSoundscapePlayer {
    private static let assetSubdirectory = "SoundscapeAssets"
    private static let playbackVolume: Float = 0.85

    private(set) var currentMode: SoundscapeMode = .none
    private(set) var state: SoundscapePlaybackState = .idle

    private var player: AVAudioPlayer?

    /// Local-only soundscape playback scaffold.
    ///
    /// This class only resolves bundled app resources and passes those local
    /// files into AVAudioPlayer. It must never stream from the network, call a
    /// cloud API, use Endel APIs/assets, read Apple Music or MusicKit content,
    /// access the microphone, inspect screenshots, capture keystrokes, read the
    /// clipboard, scrape page text, or start playback without an explicit user
    /// action.
    ///
    /// Future bundled sound files must be CC0, royalty-free with compatible
    /// redistribution rights, or original. Local-only playback comes before any
    /// broader integration.
    @discardableResult
    func play(_ mode: SoundscapeMode, logger: DriftLogger? = nil) -> SoundscapePlaybackState {
        log(logger, "Requested soundscape mode: \(mode.displayName)")

        guard mode != .none, let assetName = mode.defaultLocalAssetName else {
            log(logger, "Resolved asset name: none")
            let stoppedState = stop()
            log(logger, "Playback state: \(stoppedState.displayName)")
            return stoppedState
        }

        log(logger, "Resolved asset name: \(assetName)")

        guard let assetURL = bundledAssetURL(for: assetName) else {
            player?.stop()
            player = nil
            currentMode = mode
            state = .unavailable(mode)
            log(logger, "Bundle URL missing for asset: \(assetName)")
            log(logger, "Playback state: \(state.displayName)")
            return state
        }

        log(logger, "Bundle URL found: \(assetURL.lastPathComponent)")

        do {
            let localPlayer = try AVAudioPlayer(contentsOf: assetURL)
            localPlayer.volume = Self.playbackVolume
            localPlayer.numberOfLoops = mode.allowsLooping ? -1 : 0
            localPlayer.currentTime = 0
            player = localPlayer
            currentMode = mode

            log(logger, "Player duration: \(formattedDuration(localPlayer.duration)) seconds")

            localPlayer.prepareToPlay()
            let didStartPlaying = localPlayer.play()

            log(logger, "play() returned \(didStartPlaying)")

            if didStartPlaying {
                state = .playing(mode)
            } else {
                localPlayer.stop()
                player = nil
                state = .failed(mode, "Local cue failed to play.")
            }

            log(logger, "Playback state: \(state.displayName)")
            return state
        } catch {
            player = nil
            currentMode = mode
            state = .failed(mode, "Local cue failed to play.")
            log(logger, "Player creation failed: \(error.localizedDescription)")
            log(logger, "Playback state: \(state.displayName)")
            return state
        }
    }

    func isAssetAvailable(for mode: SoundscapeMode) -> Bool {
        guard mode != .none, let assetName = mode.defaultLocalAssetName else {
            return false
        }

        return bundledAssetURL(for: assetName) != nil
    }

    @discardableResult
    func pause() -> SoundscapePlaybackState {
        guard let player, currentMode != .none else {
            state = .idle
            return state
        }

        player.pause()
        state = .paused(currentMode)
        return state
    }

    @discardableResult
    func stop() -> SoundscapePlaybackState {
        player?.stop()
        player?.currentTime = 0
        player = nil
        currentMode = .none
        state = .idle
        return state
    }

    deinit {
        player?.stop()
    }

    private func bundledAssetURL(for assetName: String) -> URL? {
        let asset = URL(fileURLWithPath: assetName)
        let resource = asset.deletingPathExtension().lastPathComponent
        let fileExtension = asset.pathExtension

        if fileExtension.isEmpty {
            return Bundle.main.url(forResource: assetName, withExtension: nil)
                ?? Bundle.main.url(
                    forResource: assetName,
                    withExtension: nil,
                    subdirectory: Self.assetSubdirectory
                )
        }

        return Bundle.main.url(forResource: resource, withExtension: fileExtension)
            ?? Bundle.main.url(
                forResource: resource,
                withExtension: fileExtension,
                subdirectory: Self.assetSubdirectory
            )
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        String(format: "%.2f", duration)
    }

    private func log(_ logger: DriftLogger?, _ message: String) {
        logger?.log(.soundscape, message)
    }
}
