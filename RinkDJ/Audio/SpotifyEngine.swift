import Foundation
import Observation

// The real implementation is used once the Spotify iOS SDK Swift package is added to
// the project. Until then (and so the app keeps building on any machine before the
// package resolves) a logging stub with the same API is compiled instead — see the
// `#else` branch. Both are `@Observable` so views and `PlaybackCoordinator` bind to
// the same surface either way.
#if canImport(SpotifyiOS)
import SpotifyiOS

/// Controls Spotify playback through the Spotify app on the same device via
/// `SPTAppRemote`. Implements the `AudioEngine` strategy so `PlaybackCoordinator`
/// routes `.spotify(uri:)` resources here exactly like it routes local files to
/// `LocalAudioEngine`.
///
/// Auth uses the App Remote bootstrap flow (no backend, no client secret): `authorize()`
/// opens the Spotify app, the user approves, and the token returns via the redirect URI
/// (`handle(url:)`). Requires a physical device, the Spotify app, and Premium — it is
/// inert in the Simulator.
@Observable
final class SpotifyEngine: NSObject, AudioEngine {
    /// Whether App Remote is connected to the Spotify app.
    private(set) var isConnected = false
    /// Human-readable status shown on the Spotify screen (Swedish).
    private(set) var statusMessage = "Inte ansluten"
    /// Last error to surface in the UI, if any.
    private(set) var connectionError: String?
    /// "Title – Artist" of the current Spotify track, for the UI.
    private(set) var nowPlaying: String?

    /// The current OAuth access token, used by `SpotifyWebAPI` to list the user's
    /// playlists. Present as soon as `handle(url:)` receives it — before App Remote's
    /// socket finishes connecting. `nil` until the user authorizes.
    var accessToken: String? { appRemote.connectionParameters.accessToken }

    /// OAuth scopes requested so the same token can also list the user's playlists via
    /// the Web API. Reused when relaunching Spotify to resume playback.
    private static let authScopes = ["playlist-read-private", "playlist-read-collaborative"]

    /// A playback action deferred until App Remote finishes connecting.
    @ObservationIgnored private var pendingAction: (() -> Void)?
    /// Fired when the current one-shot ends naturally (Icing/Off-side → Avblåsning chain).
    @ObservationIgnored private var oneShotCompletion: (() -> Void)?
    @ObservationIgnored private var oneShotEndWork: DispatchWorkItem?

    @ObservationIgnored private lazy var appRemote: SPTAppRemote = {
        let configuration = SPTConfiguration(clientID: SpotifyConfig.clientID,
                                             redirectURL: SpotifyConfig.redirectURI)
        let remote = SPTAppRemote(configuration: configuration, logLevel: .info)
        remote.delegate = self
        return remote
    }()

    // MARK: - Connection lifecycle

    /// Start OAuth: opens the Spotify app so the user can approve access. The access
    /// token comes back via the redirect URI, handled in `handle(url:)`.
    func authorize() {
        connectionError = nil
        statusMessage = "Ansluter…"
        // Empty URI = authorize only (don't start playing anything yet). `success`
        // reports whether the Spotify app launched; the token arrives via handle(url:).
        // `playlist-read-*` scopes let the same token read the user's playlists via the
        // Web API (see SpotifyWebAPI) so they can be picked in Setup.
        appRemote.authorizeAndPlayURI("",
                                      asRadio: false,
                                      additionalScopes: Self.authScopes) { [weak self] success in
            if !success {
                self?.connectionError = "Spotify-appen är inte installerad på den här enheten."
                self?.statusMessage = "Inte ansluten"
            }
        }
    }

    /// Handle the OAuth redirect delivered to `.onOpenURL` in `RinkDJApp`.
    func handle(url: URL) {
        let params = appRemote.authorizationParameters(from: url)
        if let token = params?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = token
            appRemote.connect()
        } else if let error = params?[SPTAppRemoteErrorDescriptionKey] {
            connectionError = error
            statusMessage = "Inte ansluten"
        }
    }

    /// Reconnect when returning to the foreground, if we already have a token.
    func connectIfPossible() {
        guard !appRemote.isConnected,
              appRemote.connectionParameters.accessToken != nil else { return }
        appRemote.connect()
    }

    func disconnect() {
        appRemote.disconnect()
    }

    // MARK: - AudioEngine

    func canHandle(_ resource: AudioResource) -> Bool {
        if case .spotify = resource { return true }
        return false
    }

    func playOneShot(_ resource: AudioResource, completion: (() -> Void)?) {
        guard case .spotify(let uri, _) = resource else { completion?(); return }
        play(uri: uri) { [weak self] in
            self?.armOneShotCompletion(completion)
        }
    }

    func playPlaylist(_ resources: [AudioResource], loop: Bool) {
        guard let first = resources.first, case .spotify(let uri, _) = first else { return }
        play(uri: uri) { [weak self] in
            self?.appRemote.playerAPI?.setRepeatMode(loop ? .context : .off) { _, _ in }
        }
    }

    func playLooping(_ resource: AudioResource) {
        guard case .spotify(let uri, _) = resource else { return }
        play(uri: uri) { [weak self] in
            self?.appRemote.playerAPI?.setRepeatMode(.track) { _, _ in }
        }
    }

    func stop() {
        cancelOneShotCompletion()
        guard appRemote.isConnected else { return }
        appRemote.playerAPI?.setRepeatMode(.off) { _, _ in }
        appRemote.playerAPI?.pause { [weak self] _, error in self?.report(error) }
    }

    // MARK: - Playlist contents

    /// Read a playlist's tracks via the App Remote **content API**, which is mediated by the
    /// Spotify app and needs no Web API scope — unlike the Web API `/playlists/{id}/tracks`
    /// endpoint, which returns 403 with an App Remote token. Used to expand a picked playlist
    /// into individual stepped tracks for the Match-spellista. Requires a live connection.
    ///
    /// Note: `fetchChildrenOfContentItem` returns a single page, so very long playlists may
    /// be truncated — fine for curated game/intermission lists.
    func fetchPlaylistTracks(uri: String) async throws -> [SpotifyTrack] {
        guard appRemote.isConnected, let contentAPI = appRemote.contentAPI else {
            throw SpotifyWebAPIError.notConnected
        }
        let item: SPTAppRemoteContentItem = try await withCheckedThrowingContinuation { cont in
            contentAPI.fetchContentItem(forURI: uri) { result, error in
                if let error { cont.resume(throwing: error) }
                else if let item = result as? SPTAppRemoteContentItem { cont.resume(returning: item) }
                else { cont.resume(throwing: SpotifyWebAPIError.decoding) }
            }
        }
        let children: [SPTAppRemoteContentItem] = try await withCheckedThrowingContinuation { cont in
            contentAPI.fetchChildren(of: item) { result, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: (result as? [SPTAppRemoteContentItem]) ?? []) }
            }
        }
        return children.compactMap { child in
            guard child.isPlayable else { return nil }
            let title = child.title ?? child.uri
            if let artist = child.subtitle, !artist.isEmpty {
                return SpotifyTrack(uri: child.uri, name: "\(title) – \(artist)")
            }
            return SpotifyTrack(uri: child.uri, name: title)
        }
    }

    // MARK: - Helpers

    /// Play a Spotify URI, then apply `postPlay` (repeat mode, or arming the one-shot
    /// completion) once playback has started. Handles three connection states:
    ///  - Connected: play directly over App Remote.
    ///  - Disconnected but already authorized: the Spotify app was most likely *suspended*
    ///    by iOS while we kept it paused during a local sound — the App Remote socket drops
    ///    after ~20 s. A plain `connect()` cannot wake a suspended app, so relaunch it with
    ///    the URI via `authorizeAndPlayURI` (which can); `postPlay` runs once the connection
    ///    re-establishes. This is what lets Avblåsning play the next Spotify track after a
    ///    long event sound.
    ///  - No token yet: authorize (which opens Spotify), then play + `postPlay` on connect.
    private func play(uri: String, postPlay: @escaping () -> Void) {
        if appRemote.isConnected {
            appRemote.playerAPI?.play(uri) { [weak self] _, error in
                self?.report(error)
                postPlay()
            }
        } else if appRemote.connectionParameters.accessToken != nil {
            pendingAction = postPlay
            appRemote.authorizeAndPlayURI(uri, asRadio: false,
                                          additionalScopes: Self.authScopes) { [weak self] success in
                if !success { self?.connectionError = "Kunde inte återansluta till Spotify." }
            }
        } else {
            pendingAction = { [weak self] in
                self?.appRemote.playerAPI?.play(uri) { _, error in
                    self?.report(error)
                    postPlay()
                }
            }
            authorize()
        }
    }

    private func report(_ error: Error?) {
        if let error { connectionError = error.localizedDescription }
    }

    /// Arm a one-shot completion by scheduling it for when the track should finish.
    /// Spotify has no reliable "track ended" callback for a single track, so we time it
    /// from the track's remaining duration — good enough for the Icing/Off-side chain,
    /// and cancelled by `stop()` or the next playback action.
    private func armOneShotCompletion(_ completion: (() -> Void)?) {
        cancelOneShotCompletion()
        guard let completion else { return }
        oneShotCompletion = completion
        appRemote.playerAPI?.getPlayerState { [weak self] state, _ in
            guard let self, let state = state as? SPTAppRemotePlayerState else { return }
            let remaining = Int(state.track.duration) - Int(state.playbackPosition)
            self.scheduleOneShotCompletion(afterMs: remaining)
        }
    }

    private func scheduleOneShotCompletion(afterMs ms: Int) {
        let work = DispatchWorkItem { [weak self] in
            guard let self, let completion = self.oneShotCompletion else { return }
            self.oneShotCompletion = nil
            completion()
        }
        oneShotEndWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(max(0, ms)), execute: work)
    }

    private func cancelOneShotCompletion() {
        oneShotEndWork?.cancel()
        oneShotEndWork = nil
        oneShotCompletion = nil
    }
}

// MARK: - SPTAppRemoteDelegate

extension SpotifyEngine: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        isConnected = true
        connectionError = nil
        statusMessage = "Ansluten till Spotify"
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { _, _ in })
        let action = pendingAction
        pendingAction = nil
        action?()
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        isConnected = false
        statusMessage = "Inte ansluten"
        connectionError = error?.localizedDescription ?? "Kunde inte ansluta till Spotify."
        pendingAction = nil
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        isConnected = false
        statusMessage = "Inte ansluten"
        if let error { connectionError = error.localizedDescription }
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate

extension SpotifyEngine: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        nowPlaying = "\(playerState.track.name) – \(playerState.track.artist.name)"
    }
}

#else

/// Logging stub used until the Spotify iOS SDK package is added. Keeps the app building
/// and running (Simulator/Phase 1) with the exact API the rest of the app expects.
@Observable
final class SpotifyEngine: AudioEngine {
    private(set) var isConnected = false
    private(set) var statusMessage = "Inte ansluten (Spotify-SDK saknas)"
    private(set) var connectionError: String?
    private(set) var nowPlaying: String?

    /// No token without the SDK; the playlist picker shows its "connect" state instead.
    var accessToken: String? { nil }

    func authorize() { log("authorize") }
    func handle(url: URL) { log("handle \(url)") }
    func connectIfPossible() {}
    func disconnect() {}

    func canHandle(_ resource: AudioResource) -> Bool {
        if case .spotify = resource { return true }
        return false
    }

    func playOneShot(_ resource: AudioResource, completion: (() -> Void)?) {
        log("would play \(resource.displayName)")
        // Preserve the Icing/Off-side → Avblåsning chain when nothing really plays.
        completion?()
    }

    func playPlaylist(_ resources: [AudioResource], loop: Bool) {
        resources.forEach { log("would play \($0.displayName)") }
    }

    func playLooping(_ resource: AudioResource) { log("would loop \(resource.displayName)") }
    func stop() {}

    func fetchPlaylistTracks(uri: String) async throws -> [SpotifyTrack] { [] }

    private func log(_ message: String) {
        print("SpotifyEngine (SDK not linked): \(message)")
    }
}

#endif
