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
        self.config = Self.load() ?? .demo
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
}
