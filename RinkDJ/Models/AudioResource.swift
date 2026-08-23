import Foundation

/// A single piece of audio that can be played for an event or as part of a playlist.
///
/// This is the abstraction the plan calls out: audio can come from either a local
/// file or (in Phase 2) Spotify. In Java you'd model this as an interface with two
/// implementations; the idiomatic Swift equivalent is an enum with associated
/// values (a "sum type"). `PlaybackCoordinator` switches on the case to decide
/// which engine handles it.
enum AudioResource: Codable, Hashable, Identifiable {
    /// A local audio file. `fileName` is resolved at play time: first from the
    /// app's Documents/ImportedAudio directory (user imports), otherwise from the
    /// app bundle (shipped demo sounds).
    case localFile(fileName: String)

    /// A Spotify track or playlist URI, e.g. "spotify:track:...". Wired up in Phase 2.
    case spotify(uri: String)

    var id: String {
        switch self {
        case .localFile(let name): return "local:\(name)"
        case .spotify(let uri):    return "spotify:\(uri)"
        }
    }

    /// Human-friendly name for lists in Setup.
    var displayName: String {
        switch self {
        case .localFile(let name):
            return (name as NSString).lastPathComponent
        case .spotify(let uri):
            return uri
        }
    }

    /// Short badge text describing where the audio comes from.
    var sourceLabel: String {
        switch self {
        case .localFile: return "MP3"
        case .spotify:   return "Spotify"
        }
    }
}
