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
