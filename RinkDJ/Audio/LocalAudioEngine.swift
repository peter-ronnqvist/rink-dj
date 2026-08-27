import Foundation
import AVFoundation

/// Plays local audio files with `AVAudioPlayer`. Handles `.localFile` resources only.
///
/// Subclasses `NSObject` so it can be the `AVAudioPlayerDelegate` — that's how we get
/// notified when a track finishes, to auto-advance an intermission playlist.
final class LocalAudioEngine: NSObject, AudioEngine, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?

    /// When playing an intermission playlist we keep the queue + position here so we
    /// can advance to the next file when the current one ends.
    private var queue: [URL] = []
    private var queueIndex = 0
    private var loopQueue = false

    /// Called when the current one-shot finishes on its own (not on stop/replace).
    /// Used to chain Icing/Off-side into an Avblåsning once their sound has played.
    private var oneShotCompletion: (() -> Void)?

    override init() {
        super.init()
        configureSession()
    }

    /// Route audio to playback so it sounds even with the silent switch on, and use
    /// `.mixWithOthers` so activating our session doesn't interrupt other apps. Without
    /// it, a plain `.playback` session is *interrupting*: iOS suspends the Spotify app
    /// when we activate, which drops the `SPTAppRemote` connection. We already pause
    /// Spotify ourselves before playing a local sound, so mixing causes no overlap.
    private func configureSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession setup failed: \(error)")
        }
        #endif
    }

    // MARK: AudioEngine

    func canHandle(_ resource: AudioResource) -> Bool {
        if case .localFile = resource { return true }
        return false
    }

    func playOneShot(_ resource: AudioResource, completion: (() -> Void)?) {
        guard case .localFile(let fileName) = resource,
              let url = FileStore.resolveAudioURL(fileName: fileName) else {
            print("LocalAudioEngine: could not resolve \(resource)")
            return
        }
        queue = []           // a one-shot cancels any running playlist
        oneShotCompletion = completion
        startPlaying(url: url)
    }

    func playPlaylist(_ resources: [AudioResource], loop: Bool) {
        let urls = resources.compactMap { resource -> URL? in
            guard case .localFile(let fileName) = resource else { return nil }
            return FileStore.resolveAudioURL(fileName: fileName)
        }
        guard !urls.isEmpty else { stop(); return }
        oneShotCompletion = nil     // playlists don't chain
        queue = urls
        queueIndex = 0
        loopQueue = loop
        startPlaying(url: urls[0])
    }

    func playLooping(_ resource: AudioResource) {
        guard case .localFile(let fileName) = resource,
              let url = FileStore.resolveAudioURL(fileName: fileName) else {
            print("LocalAudioEngine: could not resolve \(resource)")
            return
        }
        queue = []           // a single looping track, not a playlist
        oneShotCompletion = nil     // a loop never finishes on its own
        // numberOfLoops = -1 loops the file seamlessly until we stop it.
        startPlaying(url: url, numberOfLoops: -1)
    }

    func stop() {
        player?.stop()
        player = nil
        queue = []
        oneShotCompletion = nil     // interrupted, so don't chain
    }

    // MARK: Playback

    private func startPlaying(url: URL, numberOfLoops: Int = 0) {
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.numberOfLoops = numberOfLoops
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
        } catch {
            print("LocalAudioEngine failed to play \(url.lastPathComponent): \(error)")
        }
    }

    // MARK: AVAudioPlayerDelegate — auto-advance a running playlist

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard !queue.isEmpty else {
            // A one-shot finished. If something was chained to it (Icing/Off-side →
            // Avblåsning), run it now. Clear first so it can't fire twice.
            let completion = oneShotCompletion
            oneShotCompletion = nil
            completion?()
            return
        }
        queueIndex += 1
        if queueIndex >= queue.count {
            guard loopQueue else { queue = []; return }
            queueIndex = 0
        }
        startPlaying(url: queue[queueIndex])
    }
}
