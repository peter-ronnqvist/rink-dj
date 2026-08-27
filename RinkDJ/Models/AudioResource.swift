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

    /// A Spotify track or playlist URI, e.g. "spotify:track:...". `name` is an optional
    /// human-friendly label ("Title – Artist" for tracks, the playlist name for playlists)
    /// captured when the item is picked from Spotify, so lists don't show raw URIs. It is
    /// optional so older saved configs (which stored only a URI) still decode — the
    /// synthesized decoder fills it with `nil`.
    case spotify(uri: String, name: String? = nil)

    var id: String {
        switch self {
        case .localFile(let name): return "local:\(name)"
        case .spotify(let uri, _): return "spotify:\(uri)"
        }
    }

    /// Human-friendly name for lists in Setup.
    var displayName: String {
        switch self {
        case .localFile(let name):
            return (name as NSString).lastPathComponent
        case .spotify(let uri, let name):
            return name ?? uri
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
