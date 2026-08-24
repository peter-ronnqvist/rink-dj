import Foundation

/// Something that can play `AudioResource`s. This is the interface (Java: `interface`)
/// behind the plan's strategy pattern — `LocalAudioEngine` handles local files today,
/// `SpotifyEngine` will handle Spotify URIs in Phase 2. `PlaybackCoordinator` asks each
/// engine `canHandle(_:)` and routes the resource to the one that says yes.
protocol AudioEngine: AnyObject {
    /// True if this engine knows how to play the given resource.
    func canHandle(_ resource: AudioResource) -> Bool

    /// Play a single resource once (used for goals, penalties, timeout, game end,
    /// and each stepped track of the game playlist). `completion` fires when the track
    /// finishes on its own — used by Icing/Off-side to chain into Avblåsning afterwards.
    /// It is not called if playback is interrupted by `stop()` or a new track.
    func playOneShot(_ resource: AudioResource, completion: (() -> Void)?)

    /// Play a list of resources in order, optionally looping (used for intermission).
    func playPlaylist(_ resources: [AudioResource], loop: Bool)

    /// Play a single resource on repeat until stopped (used for the Timeout cricket loop).
    func playLooping(_ resource: AudioResource)

    /// Stop whatever this engine is currently playing.
    func stop()
}

extension AudioEngine {
    /// Convenience for the common case of a one-shot with nothing to do afterwards.
    func playOneShot(_ resource: AudioResource) {
        playOneShot(resource, completion: nil)
    }
}
