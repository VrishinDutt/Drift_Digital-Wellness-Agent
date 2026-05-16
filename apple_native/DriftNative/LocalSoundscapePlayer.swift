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
            return "Soundscape asset unavailable."
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
    func play(_ mode: SoundscapeMode) -> SoundscapePlaybackState {
        guard mode != .none, let assetName = mode.defaultLocalAssetName else {
            return stop()
        }

        guard let assetURL = bundledAssetURL(for: assetName) else {
            player?.stop()
            player = nil
            currentMode = mode
            state = .unavailable(mode)
            return state
        }

        do {
            let localPlayer = try AVAudioPlayer(contentsOf: assetURL)
            localPlayer.numberOfLoops = mode.allowsLooping ? -1 : 0
            localPlayer.prepareToPlay()
            localPlayer.play()

            player = localPlayer
            currentMode = mode
            state = .playing(mode)
            return state
        } catch {
            player = nil
            currentMode = mode
            state = .failed(mode, "Soundscape asset unavailable.")
            return state
        }
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
}
