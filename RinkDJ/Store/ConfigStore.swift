import Foundation
import Observation

/// Loads, holds and saves the app configuration. Marked `@Observable` (iOS 17+),
/// which is the modern SwiftUI way to make a reference type that views observe —
/// think of it like a singleton service/bean that the UI binds to. Views read
/// `store.config` and call `store.save()` after edits.
@Observable
final class ConfigStore {
    var config: AppConfig

    init() {
        let loaded = Self.load()
        self.config = loaded ?? .demo
        if loaded != nil {
            // Upgrade configs saved before events held a *list* of tracks: fold each
            // single track into a one-item list.
            migrateLegacyEventTracks()
            // A saved config from an earlier version won't contain events added later
            // (e.g. Icing/Off-side). Backfill their bundled defaults so they aren't silent.
            backfillMissingEventDefaults()
        }
    }

    // MARK: - Persistence (single JSON file in Documents)

    private static var configURL: URL {
        FileStore.documents.appendingPathComponent("config.json")
    }

    private static func load() -> AppConfig? {
        guard let data = try? Data(contentsOf: configURL) else { return nil }
        return try? JSONDecoder().decode(AppConfig.self, from: data)
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: Self.configURL, options: .atomic)
        } catch {
            print("ConfigStore save failed: \(error)")
        }
    }

    /// Reset back to the bundled demo configuration.
    func resetToDemo() {
        config = .demo
        save()
    }

    /// Restore every event's sound to the bundled defaults, leaving the playlists and
    /// team branding untouched. Recovers the case where a sound was cleared or changed
    /// and the bundled default (e.g. FlempanGoal.mp3) can't be re-picked from Files.
    func restoreDefaultEventSounds() {
        config.eventTrackLists = AppConfig.demo.eventTrackLists
        save()
    }

    /// Fold a pre-list config's single-track-per-event map into `eventTrackLists`, one item
    /// per event, then clear the legacy field so it's never written again. Only events not
    /// already present in `eventTrackLists` are migrated, so a partially-upgraded config is
    /// left alone.
    private func migrateLegacyEventTracks() {
        guard let legacy = config.eventTracks else { return }
        for (key, resource) in legacy where config.eventTrackLists[key] == nil {
            config.eventTrackLists[key] = [resource]
        }
        config.eventTracks = nil
        save()
    }

    /// Give any event with no bound tracks its bundled default list. Unlike
    /// `restoreDefaultEventSounds`, this only fills gaps — sounds the user has already
    /// chosen are kept. Used on launch so events added in an update start with a sound.
    private func backfillMissingEventDefaults() {
        var changed = false
        for (key, resources) in AppConfig.demo.eventTrackLists
        where (config.eventTrackLists[key] ?? []).isEmpty {
            config.eventTrackLists[key] = resources
            changed = true
        }
        if changed { save() }
    }

    // MARK: - Importing files chosen by the user

    /// Copy a user-picked audio file into the app's imported-audio folder and return
    /// a resource referencing it. The file name is later resolved by `LocalAudioEngine`.
    func importAudio(from pickedURL: URL) -> AudioResource? {
        guard let fileName = FileStore.copyIntoImportedAudio(from: pickedURL) else { return nil }
        return .localFile(fileName: fileName)
    }

    /// Copy a user-picked logo image into the branding folder and record it.
    func importLogo(from pickedURL: URL) {
        if let fileName = FileStore.copyIntoBranding(from: pickedURL) {
            config.branding.logoFileName = fileName
            save()
        }
    }

    /// Store raw logo image bytes (from the Photos picker) into the branding folder and record it.
    func importLogo(data: Data, suggestedName: String = "logo.png") {
        if let fileName = FileStore.saveIntoBranding(data: data, suggestedName: suggestedName) {
            config.branding.logoFileName = fileName
            save()
        }
    }
}
