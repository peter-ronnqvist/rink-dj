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

    override init() {
        super.init()
        configureSession()
    }

    /// Route audio to playback so it sounds even with the silent switch on, and mixes
    /// politely if something else is playing.
    private func configureSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
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

    func playOneShot(_ resource: AudioResource) {
        guard case .localFile(let fileName) = resource,
              let url = FileStore.resolveAudioURL(fileName: fileName) else {
            print("LocalAudioEngine: could not resolve \(resource)")
            return
        }
        queue = []           // a one-shot cancels any running playlist
        startPlaying(url: url)
    }

    func playPlaylist(_ resources: [AudioResource], loop: Bool) {
        let urls = resources.compactMap { resource -> URL? in
            guard case .localFile(let fileName) = resource else { return nil }
            return FileStore.resolveAudioURL(fileName: fileName)
        }
        guard !urls.isEmpty else { stop(); return }
        queue = urls
        queueIndex = 0
        loopQueue = loop
        startPlaying(url: urls[0])
    }

    func stop() {
        player?.stop()
        player = nil
        queue = []
    }

    // MARK: Playback

    private func startPlaying(url: URL) {
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
        } catch {
            print("LocalAudioEngine failed to play \(url.lastPathComponent): \(error)")
        }
    }

    // MARK: AVAudioPlayerDelegate — auto-advance a running playlist

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard !queue.isEmpty else { return }   // one-shot finished; nothing to do
        queueIndex += 1
        if queueIndex >= queue.count {
            guard loopQueue else { queue = []; return }
            queueIndex = 0
        }
        startPlaying(url: queue[queueIndex])
    }
}
