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

    /// Ordered list of tracks bound to each configurable event, keyed by `GameEvent.rawValue`.
    /// (Keyed by String rather than the enum so the JSON is a clean object.) Each event button
    /// steps through its list round-robin — see `PlaybackCoordinator`. Optional-with-default so
    /// configs saved before lists existed still decode.
    var eventTrackLists: [String: [AudioResource]] = [:]

    /// Legacy single-track-per-event storage, kept only so pre-list configs can be migrated to
    /// `eventTrackLists` on launch (see `ConfigStore.migrateLegacyEventTracks`). Optional so the
    /// synthesized encoder omits it once migration has cleared it — new configs never write it.
    var eventTracks: [String: AudioResource]? = nil

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

    func tracks(for event: GameEvent) -> [AudioResource] {
        eventTrackLists[event.rawValue] ?? []
    }

    mutating func setTracks(_ resources: [AudioResource], for event: GameEvent) {
        eventTrackLists[event.rawValue] = resources
    }

    /// The out-of-the-box default track list bound to an event (empty if it has none). Used by
    /// Setup to offer a "restore default sound" action, since the file importer can only
    /// browse user files — not the sounds bundled inside the app.
    static func defaultTracks(for event: GameEvent) -> [AudioResource] {
        demo.eventTrackLists[event.rawValue] ?? []
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
            eventTrackLists: [
                GameEvent.icing.rawValue:          [.localFile(fileName: "icing.mp3")],
                GameEvent.offside.rawValue:        [.localFile(fileName: "offside.mp3")],
                GameEvent.hemmamal.rawValue:       [.localFile(fileName: "FlempanGoal.mp3")],
                GameEvent.bortamal.rawValue:       [.localFile(fileName: "frolic.mp3")],
                GameEvent.hemmautvisning.rawValue: [.localFile(fileName: "wopwop.mp3")],
                GameEvent.bortautvisning.rawValue: [.localFile(fileName: "wopwop.mp3")],
                GameEvent.fulltalig.rawValue:      [.localFile(fileName: "fullStrength.mp3")],
                GameEvent.timeout.rawValue:        [.localFile(fileName: "cricket.mp3")],
                GameEvent.matchslut.rawValue:      [.localFile(fileName: "wopwop.mp3")]
            ],
            branding: .flemingsbergsIK,
            advancedMode: false
        )
    }
}
