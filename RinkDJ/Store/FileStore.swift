import Foundation

/// Small helper for the on-disk locations the app uses inside its sandbox.
/// Keeps all file-system paths in one place.
enum FileStore {
    static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var importedAudio: URL { subdirectory("ImportedAudio") }
    static var branding: URL { subdirectory("Branding") }

    private static func subdirectory(_ name: String) -> URL {
        let url = documents.appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Resolve an audio file name to a playable URL: prefer the user's imported copy,
    /// otherwise fall back to a file bundled with the app. Returns nil if neither exists.
    static func resolveAudioURL(fileName: String) -> URL? {
        let imported = importedAudio.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: imported.path) { return imported }

        let base = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        if let bundled = Bundle.main.url(forResource: base, withExtension: ext.isEmpty ? nil : ext) {
            return bundled
        }
        return nil
    }

    /// File names of the audio bundled inside the app (mp3/wav), sorted. These are the
    /// shipped sounds a user can assign to any event from the picker — the file importer
    /// can only reach user files, not the bundle. The `demo_*` placeholder tones are
    /// excluded; they remain valid as defaults but aren't offered for selection.
    static func bundledAudioFileNames() -> [String] {
        let urls = ["mp3", "wav"].flatMap {
            Bundle.main.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? []
        }
        return urls
            .map { $0.lastPathComponent }
            .filter { !$0.lowercased().hasPrefix("demo_") }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// URL of a user-imported branding logo, if the file still exists.
    static func brandingLogoURL(fileName: String) -> URL? {
        let url = branding.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    @discardableResult
    static func copyIntoImportedAudio(from source: URL) -> String? {
        copy(from: source, into: importedAudio)
    }

    @discardableResult
    static func copyIntoBranding(from source: URL) -> String? {
        copy(from: source, into: branding)
    }

    /// Save raw image bytes (e.g. from a Photos picker, which yields `Data` rather than a
    /// file URL) into the branding folder, returning the stored file name.
    @discardableResult
    static func saveIntoBranding(data: Data, suggestedName: String = "logo.png") -> String? {
        let destination = uniqueDestination(for: suggestedName, in: branding)
        do {
            try data.write(to: destination, options: .atomic)
            return destination.lastPathComponent
        } catch {
            print("FileStore save failed: \(error)")
            return nil
        }
    }

    /// Copy a security-scoped picked file into a destination folder, returning the
    /// stored file name. Handles the sandbox access dance required by the file importer.
    private static func copy(from source: URL, into folder: URL) -> String? {
        let needsScope = source.startAccessingSecurityScopedResource()
        defer { if needsScope { source.stopAccessingSecurityScopedResource() } }

        let destination = uniqueDestination(for: source.lastPathComponent, in: folder)
        do {
            try FileManager.default.copyItem(at: source, to: destination)
            return destination.lastPathComponent
        } catch {
            print("FileStore copy failed: \(error)")
            return nil
        }
    }

    /// Avoid clobbering an existing file by appending -1, -2, … if needed.
    private static func uniqueDestination(for fileName: String, in folder: URL) -> URL {
        let fm = FileManager.default
        var candidate = folder.appendingPathComponent(fileName)
        let base = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        var counter = 1
        while fm.fileExists(atPath: candidate.path) {
            let newName = ext.isEmpty ? "\(base)-\(counter)" : "\(base)-\(counter).\(ext)"
            candidate = folder.appendingPathComponent(newName)
            counter += 1
        }
        return candidate
    }
}
