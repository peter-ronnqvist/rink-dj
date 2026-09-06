import Foundation
import Observation

/// Turns a tapped `GameEvent` into the right audio action, routing each resource to
/// whichever engine can handle it. This is the heart of the app's business logic —
/// the part that replaces all the manual play/pause/skip juggling in the Spotify app.
///
/// `@Observable` so the Control screen can show a live "now playing" line.
@Observable
final class PlaybackCoordinator {
    /// Text shown in the now-playing bar on the Control screen.
    private(set) var nowPlaying: String = "Inget spelas"

    /// The resource currently playing, so the now-playing bar can attribute the source
    /// (e.g. show the Spotify logo for `.spotify` tracks). `nil` when nothing is playing.
    private(set) var nowPlayingResource: AudioResource?

    /// Which event was triggered last (used to highlight the button briefly).
    private(set) var lastEvent: GameEvent?

    /// Position within the game playlist; advances on every "Avblåsning".
    private(set) var gamePlaylistIndex: Int = -1

    /// Per-event cursor into each event's track list, keyed by `GameEvent.rawValue`. Each press
    /// of an event button advances its cursor round-robin (see `nextEventTrack`). Runtime-only —
    /// like `gamePlaylistIndex`, it resets on app relaunch and isn't persisted.
    private var eventTrackIndices: [String: Int] = [:]

    private let engines: [AudioEngine]

    init(engines: [AudioEngine] = [LocalAudioEngine(), SpotifyEngine()]) {
        self.engines = engines
    }

    /// Entry point from the Control screen.
    func handle(_ event: GameEvent, config: AppConfig) {
        lastEvent = event

        switch event.action {
        case .stopAll:
            stop()
            nowPlaying = "Stoppad (\(event.title))"

        case .advanceGamePlaylist:
            advanceGamePlaylist(config.gamePlaylist)

        case .playIntermissionPlaylist:
            // Shuffle so the pause playlist doesn't start from the top every time.
            playPlaylist(config.intermissionPlaylist.shuffled(), loop: true,
                         label: "Paus", emptyMessage: "Ingen paus-spellista vald")

        case .playConfiguredTrack:
            guard let pick = nextEventTrack(for: event, config: config) else {
                nowPlaying = "Ingen låt vald för \(event.title)"
                return
            }
            playOneShot(pick.resource)
            nowPlaying = eventNowPlaying(event, pick)

        case .playConfiguredTrackThenAdvance:
            guard let pick = nextEventTrack(for: event, config: config) else {
                // No sound bound: still behave as an Avblåsning.
                handle(.avblasning, config: config)
                return
            }
            // Play the event's own sound, then act as Avblåsning once it finishes.
            playOneShot(pick.resource) { [weak self] in
                self?.handle(.avblasning, config: config)
            }
            nowPlaying = eventNowPlaying(event, pick)

        case .playConfiguredTrackThenPaus:
            guard let pick = nextEventTrack(for: event, config: config) else {
                // No sound bound: go straight to the pause playlist.
                handle(.paus, config: config)
                return
            }
            // Play the event's own sound (e.g. Entré), then start the pause playlist.
            playOneShot(pick.resource) { [weak self] in
                self?.handle(.paus, config: config)
            }
            nowPlaying = eventNowPlaying(event, pick)

        case .playLoopedTrack:
            guard let pick = nextEventTrack(for: event, config: config) else {
                nowPlaying = "Ingen låt vald för \(event.title)"
                return
            }
            playLooping(pick.resource)
            nowPlaying = eventNowPlaying(event, pick, suffix: " (repeterar)")
        }
    }

    func stop() {
        engines.forEach { $0.stop() }
        nowPlayingResource = nil
    }

    // MARK: - Helpers

    /// One track chosen from an event's list, with its position for the now-playing label.
    private struct EventPick {
        let resource: AudioResource
        let index: Int
        let total: Int
    }

    /// Advance the round-robin cursor for `event` and return the next track to play, or `nil`
    /// when the event has no tracks configured. Mirrors `advanceGamePlaylist`'s wrap-around:
    /// the first press plays index 0, then 1, …, wrapping back to 0 after the last.
    private func nextEventTrack(for event: GameEvent, config: AppConfig) -> EventPick? {
        let tracks = config.tracks(for: event)
        guard !tracks.isEmpty else { return nil }
        let key = event.rawValue
        let next = ((eventTrackIndices[key] ?? -1) + 1) % tracks.count
        eventTrackIndices[key] = next
        return EventPick(resource: tracks[next], index: next, total: tracks.count)
    }

    /// Now-playing label for an event pick, showing the position only when the list has more
    /// than one track (a single-track button reads like it always did).
    private func eventNowPlaying(_ event: GameEvent, _ pick: EventPick, suffix: String = "") -> String {
        let position = pick.total > 1 ? " (\(pick.index + 1)/\(pick.total))" : ""
        return "\(event.title)\(suffix)\(position): \(pick.resource.displayName)"
    }

    private func advanceGamePlaylist(_ playlist: [AudioResource]) {
        guard !playlist.isEmpty else {
            nowPlaying = "Spellistan är tom – lägg till låtar i Inställningar"
            return
        }
        gamePlaylistIndex = (gamePlaylistIndex + 1) % playlist.count
        let track = playlist[gamePlaylistIndex]
        playOneShot(track)
        nowPlaying = "Spellista \(gamePlaylistIndex + 1)/\(playlist.count): \(track.displayName)"
    }

    private func playPlaylist(_ playlist: [AudioResource], loop: Bool,
                              label: String, emptyMessage: String) {
        guard !playlist.isEmpty else { nowPlaying = emptyMessage; return }
        stop()
        // Route the whole playlist to the engine that handles its first track.
        if let engine = engine(for: playlist[0]) {
            engine.playPlaylist(playlist, loop: loop)
            nowPlayingResource = playlist[0]
            nowPlaying = "\(label): \(playlist[0].displayName)"
        }
    }

    private func playOneShot(_ resource: AudioResource, completion: (() -> Void)? = nil) {
        stop()
        engine(for: resource)?.playOneShot(resource, completion: completion)
        nowPlayingResource = resource
    }

    private func playLooping(_ resource: AudioResource) {
        stop()
        engine(for: resource)?.playLooping(resource)
        nowPlayingResource = resource
    }

    private func engine(for resource: AudioResource) -> AudioEngine? {
        engines.first { $0.canHandle(resource) }
    }
}
