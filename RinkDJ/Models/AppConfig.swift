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

    /// When off (the default), the Match screen shows only the core buttons; when on,
    /// every event button is shown. Optional so configs saved before this flag existed
    /// still decode — a missing value is treated as "off" via ``isAdvanced``.
    var advancedMode: Bool? = nil

    // MARK: Convenience accessors

    /// Whether the advanced (all-buttons) Match layout is active.
    var isAdvanced: Bool {
        get { advancedMode ?? false }
        set { advancedMode = newValue }
    }

    func track(for event: GameEvent) -> AudioResource? {
        eventTracks[event.rawValue]
    }

    mutating func setTrack(_ resource: AudioResource?, for event: GameEvent) {
        eventTracks[event.rawValue] = resource
    }

    /// The out-of-the-box default track bound to an event (nil if it has none). Used by
    /// Setup to offer a "restore default sound" action, since the file importer can only
    /// browse user files — not the sounds bundled inside the app.
    static func defaultTrack(for event: GameEvent) -> AudioResource? {
        demo.eventTracks[event.rawValue]
    }

    // MARK: Default configuration

    /// Sensible out-of-the-box config using the sounds bundled with the app.
    static var demo: AppConfig {
        AppConfig(
            // The Match-spellista is built from a Spotify playlist, so it starts empty.
            gamePlaylist: [],
            // The Paus-spellista holds one whole Spotify playlist (or nothing); it has no
            // local demo seed, so it starts empty until a Spotify playlist is picked.
            intermissionPlaylist: [],
            eventTracks: [
                GameEvent.icing.rawValue:          .localFile(fileName: "icing.mp3"),
                GameEvent.offside.rawValue:        .localFile(fileName: "offside.mp3"),
                GameEvent.hemmamal.rawValue:       .localFile(fileName: "FlempanGoal.mp3"),
                GameEvent.bortamal.rawValue:       .localFile(fileName: "frolic.mp3"),
                GameEvent.hemmautvisning.rawValue: .localFile(fileName: "wopwop.mp3"),
                GameEvent.bortautvisning.rawValue: .localFile(fileName: "wopwop.mp3"),
                GameEvent.fulltalig.rawValue:      .localFile(fileName: "fullStrength.mp3"),
                GameEvent.timeout.rawValue:        .localFile(fileName: "cricket.mp3"),
                GameEvent.matchslut.rawValue:      .localFile(fileName: "wopwop.mp3")
            ],
            branding: .flemingsbergsIK,
            advancedMode: false
        )
    }
}
