import Foundation

/// Phase 2 engine that will control Spotify playback via the Spotify iOS SDK
/// (`SPTAppRemote`). It's a stub for now so the app builds and runs entirely on the
/// Simulator with local audio; the Spotify SDK requires a physical device with the
/// Spotify app installed and a Premium account, so it can't run in the Simulator.
///
/// Phase 2 will implement:
///   - OAuth via `SPTSessionManager`
///   - connect / disconnect of `SPTAppRemote`
///   - play a playlist by URI (game / intermission)
///   - play a single track URI (goals, penalties, timeout, game end)
final class SpotifyEngine: AudioEngine {
    /// Whether we're connected to the Spotify app. Always false in Phase 1.
    private(set) var isConnected = false

    func canHandle(_ resource: AudioResource) -> Bool {
        if case .spotify = resource { return true }
        return false
    }

    func playOneShot(_ resource: AudioResource) {
        logNotAvailable(resource)
    }

    func playPlaylist(_ resources: [AudioResource], loop: Bool) {
        resources.forEach(logNotAvailable)
    }

    func stop() {
        // No-op until the SDK is integrated.
    }

    private func logNotAvailable(_ resource: AudioResource) {
        print("SpotifyEngine (Phase 2, not yet implemented): would play \(resource.displayName)")
    }
}
