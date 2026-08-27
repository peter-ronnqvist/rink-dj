import Foundation

/// A Spotify playlist as shown in the picker.
struct SpotifyPlaylist: Identifiable, Hashable {
    let id: String
    let name: String
    /// Canonical `spotify:playlist:<id>` URI used for playback.
    let uri: String
    let trackCount: Int
    let imageURL: URL?
}

/// A single track pulled from a playlist, mapped to what the app needs to store.
struct SpotifyTrack: Hashable {
    /// Canonical `spotify:track:<id>` URI.
    let uri: String
    /// "Title – Artist" for display in Setup and the now-playing bar.
    let name: String
}

/// Errors surfaced to the picker UI. `status` lets the view special-case an expired token
/// (401) or a token issued before the playlist scope was granted (403).
enum SpotifyWebAPIError: Error {
    case notConnected
    case http(status: Int, detail: String?)
    case decoding
    case network(Error)
}

/// Minimal Spotify **Web API** client (`api.spotify.com`), used only to list the user's
/// playlists and read a playlist's tracks so they can be picked in Setup. Playback itself
/// still goes through the App Remote SDK (`SpotifyEngine`). The access token comes from the
/// same App Remote authorization — see `SpotifyEngine.accessToken` — which is why
/// `authorize()` requests the `playlist-read-*` scopes.
struct SpotifyWebAPI {
    private let base = URL(string: "https://api.spotify.com/v1/")!

    /// The user's own + followed playlists, newest first as Spotify returns them.
    func fetchPlaylists(token: String) async throws -> [SpotifyPlaylist] {
        var url: URL? = base.appending(path: "me/playlists").appending(queryItems: [
            URLQueryItem(name: "limit", value: "50")
        ])
        var result: [SpotifyPlaylist] = []
        while let page = url {
            let response: PlaylistsResponse = try await get(page, token: token)
            result += response.items.compactMap { item in
                guard let uri = item.uri, let name = item.name, let id = item.id else { return nil }
                return SpotifyPlaylist(id: id,
                                       name: name,
                                       uri: uri,
                                       trackCount: item.tracks?.total ?? 0,
                                       imageURL: item.images?.first?.url.flatMap(URL.init(string:)))
            }
            url = response.next.flatMap(URL.init(string:))
        }
        return result
    }

    /// All playable tracks of a playlist, paginated through `next` so the whole list is
    /// returned — not just the first ~20-item page the App Remote content API is capped at
    /// (it has no offset parameter). The caller falls back to the content API if this fails,
    /// since some older App Remote tokens were seen to 403 on this endpoint.
    func fetchPlaylistTracks(playlistID: String, token: String) async throws -> [SpotifyTrack] {
        var url: URL? = base.appending(path: "playlists/\(playlistID)/tracks").appending(queryItems: [
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "market", value: "from_token"),
            // Trim the payload to just the fields we map below.
            URLQueryItem(name: "fields", value: "next,items(track(uri,name,is_playable,artists(name)))")
        ])
        var result: [SpotifyTrack] = []
        while let page = url {
            let response: PlaylistTracksResponse = try await get(page, token: token)
            result += response.items.compactMap { item -> SpotifyTrack? in
                guard let track = item.track, let uri = track.uri, let name = track.name,
                      track.isPlayable != false else { return nil }
                if let artist = track.artists?.first?.name, !artist.isEmpty {
                    return SpotifyTrack(uri: uri, name: "\(name) – \(artist)")
                }
                return SpotifyTrack(uri: uri, name: name)
            }
            url = response.next.flatMap(URL.init(string:))
        }
        return result
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ url: URL, token: String) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SpotifyWebAPIError.network(error)
        }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            // Include Spotify's JSON error body (e.g. {"error":{"status":403,"message":"..."}})
            // and the failing path so the picker can show exactly what was rejected.
            let body = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let detail = "\(url.path) → \(body ?? "")"
            print("SpotifyWebAPI \(http.statusCode): \(detail)")
            throw SpotifyWebAPIError.http(status: http.statusCode, detail: detail)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw SpotifyWebAPIError.decoding
        }
    }

    // MARK: - Response shapes (only the fields we use)

    private struct PlaylistsResponse: Decodable {
        let items: [Item]
        let next: String?
        struct Item: Decodable {
            let id: String?
            let name: String?
            let uri: String?
            let images: [Image]?
            let tracks: Tracks?
            struct Image: Decodable { let url: String? }
            struct Tracks: Decodable { let total: Int? }
        }
    }

    private struct PlaylistTracksResponse: Decodable {
        let items: [Item]
        let next: String?
        struct Item: Decodable {
            let track: Track?
            struct Track: Decodable {
                let uri: String?
                let name: String?
                let isPlayable: Bool?
                let artists: [Artist]?
                struct Artist: Decodable { let name: String? }
                enum CodingKeys: String, CodingKey {
                    case uri, name, artists
                    case isPlayable = "is_playable"
                }
            }
        }
    }

}

/// Turns whatever the user pastes (a share link, a `spotify:` URI, or a bare id) into a
/// canonical `spotify:<type>:<id>` URI that the App Remote SDK can play. Fixes the old
/// paste flow, which stored `https://open.spotify.com/...` links verbatim — a form the
/// SDK's `play(uri:)` won't accept.
enum SpotifyURI {
    static func normalize(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Already a canonical URI, e.g. "spotify:playlist:37i9dQ...".
        if trimmed.hasPrefix("spotify:") { return trimmed }

        // Share/open link, e.g. "https://open.spotify.com/playlist/37i9dQ...?si=abc".
        if let url = URL(string: trimmed),
           let host = url.host, host.contains("spotify.com") {
            let parts = url.pathComponents.filter { $0 != "/" }
            // Handles both /playlist/<id> and /intl-sv/playlist/<id> forms.
            if let typeIndex = parts.firstIndex(where: {
                ["track", "playlist", "album", "artist", "episode", "show"].contains($0)
            }), typeIndex + 1 < parts.count {
                let type = parts[typeIndex]
                let id = parts[typeIndex + 1]
                return "spotify:\(type):\(id)"
            }
            return nil
        }

        return nil
    }
}
