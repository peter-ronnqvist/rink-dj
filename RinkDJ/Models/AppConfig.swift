import Foundation

/// The whole persisted configuration for the app: the two playlists, the track
/// bound to each configurable event, and the team branding. Plain `Codable` so it
/// serialises to a single JSON file (see `ConfigStore`). This is deliberately
/// lightweight — the config is small, so there's no need for a database/SwiftData.
struct AppConfig: Codable {
    /// Ordered list of tracks stepped through on every "Avblåsning".
    var gamePlaylist: [AudioResource]

    /// Tracks played during "Paus" (intermission).
    var intermissionPlaylist: [AudioResource]

    /// Track bound to each configurable event, keyed by `GameEvent.rawValue`.
    /// (Keyed by String rather than the enum so the JSON is a clean object.)
    var eventTracks: [String: AudioResource]

    var branding: TeamBranding

    // MARK: Convenience accessors

    func track(for event: GameEvent) -> AudioResource? {
        eventTracks[event.rawValue]
    }

    mutating func setTrack(_ resource: AudioResource?, for event: GameEvent) {
        eventTracks[event.rawValue] = resource
    }

    // MARK: Default configuration

    /// Sensible out-of-the-box config using the demo sounds bundled with the app,
    /// so the app does something audible on first launch in the Simulator.
    static var demo: AppConfig {
        AppConfig(
            gamePlaylist: [
                .localFile(fileName: "demo_track1.wav"),
                .localFile(fileName: "demo_track2.wav"),
                .localFile(fileName: "demo_track3.wav")
            ],
            intermissionPlaylist: [
                .localFile(fileName: "demo_intermission.wav")
            ],
            eventTracks: [
                GameEvent.hemmamal.rawValue:       .localFile(fileName: "FlempanGoal.mp3"),
                GameEvent.bortamal.rawValue:       .localFile(fileName: "frolic.mp3"),
                GameEvent.hemmautvisning.rawValue: .localFile(fileName: "demo_penalty.wav"),
                GameEvent.bortautvisning.rawValue: .localFile(fileName: "demo_penalty.wav"),
                GameEvent.fulltalig.rawValue:      .localFile(fileName: "fullStrength.mp3"),
                GameEvent.timeout.rawValue:        .localFile(fileName: "cricket.mp3"),
                GameEvent.matchslut.rawValue:      .localFile(fileName: "demo_matchslut.wav")
            ],
            branding: .flemingsbergsIK
        )
    }
}
