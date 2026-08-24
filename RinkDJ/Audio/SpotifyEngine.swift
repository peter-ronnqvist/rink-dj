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
        appRemote.authorizeAndPlayURI("") { [weak self] success in
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
        guard case .spotify(let uri) = resource else { completion?(); return }
        run {
            self.appRemote.playerAPI?.play(uri) { [weak self] _, error in
                self?.report(error)
            }
            self.armOneShotCompletion(completion)
        }
    }

    func playPlaylist(_ resources: [AudioResource], loop: Bool) {
        guard let first = resources.first, case .spotify(let uri) = first else { return }
        run {
            self.appRemote.playerAPI?.play(uri) { [weak self] _, error in
                self?.report(error)
                self?.appRemote.playerAPI?.setRepeatMode(loop ? .context : .off) { _, _ in }
            }
        }
    }

    func playLooping(_ resource: AudioResource) {
        guard case .spotify(let uri) = resource else { return }
        run {
            self.appRemote.playerAPI?.play(uri) { [weak self] _, error in
                self?.report(error)
                self?.appRemote.playerAPI?.setRepeatMode(.track) { _, _ in }
            }
        }
    }

    func stop() {
        cancelOneShotCompletion()
        guard appRemote.isConnected else { return }
        appRemote.playerAPI?.setRepeatMode(.off) { _, _ in }
        appRemote.playerAPI?.pause { [weak self] _, error in self?.report(error) }
    }

    // MARK: - Helpers

    /// Run a playback action now if connected, otherwise connect (or authorize) first
    /// and run it once the connection is established.
    private func run(_ action: @escaping () -> Void) {
        if appRemote.isConnected {
            action()
        } else {
            pendingAction = action
            if appRemote.connectionParameters.accessToken != nil {
                appRemote.connect()
            } else {
                authorize()
            }
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

    private func log(_ message: String) {
        print("SpotifyEngine (SDK not linked): \(message)")
    }
}

#endif
