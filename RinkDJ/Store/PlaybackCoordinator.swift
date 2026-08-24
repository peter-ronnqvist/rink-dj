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

    /// Which event was triggered last (used to highlight the button briefly).
    private(set) var lastEvent: GameEvent?

    /// Position within the game playlist; advances on every "Avblåsning".
    private(set) var gamePlaylistIndex: Int = -1

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
            playPlaylist(config.intermissionPlaylist, loop: true,
                         label: "Paus", emptyMessage: "Ingen paus-spellista vald")

        case .playConfiguredTrack:
            guard let resource = config.track(for: event) else {
                nowPlaying = "Ingen låt vald för \(event.title)"
                return
            }
            playOneShot(resource)
            nowPlaying = "\(event.title): \(resource.displayName)"

        case .playConfiguredTrackThenAdvance:
            guard let resource = config.track(for: event) else {
                // No sound bound: still behave as an Avblåsning.
                handle(.avblasning, config: config)
                return
            }
            // Play the event's own sound, then act as Avblåsning once it finishes.
            playOneShot(resource) { [weak self] in
                self?.handle(.avblasning, config: config)
            }
            nowPlaying = "\(event.title): \(resource.displayName)"

        case .playLoopedTrack:
            guard let resource = config.track(for: event) else {
                nowPlaying = "Ingen låt vald för \(event.title)"
                return
            }
            playLooping(resource)
            nowPlaying = "\(event.title) (repeterar): \(resource.displayName)"
        }
    }

    func stop() {
        engines.forEach { $0.stop() }
    }

    // MARK: - Helpers

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
            nowPlaying = "\(label): \(playlist[0].displayName)"
        }
    }

    private func playOneShot(_ resource: AudioResource, completion: (() -> Void)? = nil) {
        stop()
        engine(for: resource)?.playOneShot(resource, completion: completion)
    }

    private func playLooping(_ resource: AudioResource) {
        stop()
        engine(for: resource)?.playLooping(resource)
    }

    private func engine(for resource: AudioResource) -> AudioEngine? {
        engines.first { $0.canHandle(resource) }
    }
}
