import Foundation

/// Something that can play `AudioResource`s. This is the interface (Java: `interface`)
/// behind the plan's strategy pattern — `LocalAudioEngine` handles local files today,
/// `SpotifyEngine` will handle Spotify URIs in Phase 2. `PlaybackCoordinator` asks each
/// engine `canHandle(_:)` and routes the resource to the one that says yes.
protocol AudioEngine: AnyObject {
    /// True if this engine knows how to play the given resource.
    func canHandle(_ resource: AudioResource) -> Bool

    /// Play a single resource once (used for goals, penalties, timeout, game end,
    /// and each stepped track of the game playlist).
    func playOneShot(_ resource: AudioResource)

    /// Play a list of resources in order, optionally looping (used for intermission).
    func playPlaylist(_ resources: [AudioResource], loop: Bool)

    /// Play a single resource on repeat until stopped (used for the Timeout cricket loop).
    func playLooping(_ resource: AudioResource)

    /// Stop whatever this engine is currently playing.
    func stop()
}
