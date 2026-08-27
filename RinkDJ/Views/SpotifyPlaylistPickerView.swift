import SwiftUI

/// How a picked Spotify playlist is turned into `AudioResource`s, per playlist type:
/// - `.playlistContext` (Paus-spellista): keep the playlist whole — one `spotify:playlist:`
///   item that Spotify plays and loops.
/// - `.expandTracks` (Match-spellista): pull the playlist's songs in as individual
///   `spotify:track:` items so each Avblåsning advances to the next.
enum SpotifyPickMode {
    case playlistContext
    case expandTracks
}

/// A sheet that lists the user's Spotify playlists and adds the chosen one to a playlist
/// editor. Reads the access token from `SpotifyEngine` and the playlists from the Web API.
struct SpotifyPlaylistPickerView: View {
    let mode: SpotifyPickMode
    /// Called with the resources to append once the user picks a playlist.
    let onAdd: ([AudioResource]) -> Void

    @Environment(SpotifyEngine.self) private var spotify
    @Environment(\.dismiss) private var dismiss

    private let api = SpotifyWebAPI()

    @State private var playlists: [SpotifyPlaylist] = []
    @State private var phase: Phase = .idle
    /// Name of the playlist currently being expanded into tracks, for the progress label.
    @State private var importingName: String?

    private enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case importing
        case error(String)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Spotify-spellista")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Avbryt") { dismiss() }
                    }
                }
        }
        .task(id: spotify.accessToken) { await loadIfPossible() }
    }

    @ViewBuilder
    private var content: some View {
        if spotify.accessToken == nil {
            connectPrompt
        } else {
            switch phase {
            case .idle, .loading:
                ProgressView("Hämtar spellistor…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .importing:
                ProgressView(importingName.map { "Importerar \($0)…" } ?? "Importerar…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                errorState(message)
            case .loaded:
                playlistList
            }
        }
    }

    private var connectPrompt: some View {
        VStack(spacing: 16) {
            Image("SpotifyFullLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 36)
                .accessibilityLabel("Spotify")
            Text("Anslut till Spotify för att välja en spellista.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                spotify.authorize()
            } label: {
                Label("Anslut Spotify", systemImage: "music.note")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Försök igen") { Task { await load() } }
                .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var playlistList: some View {
        List {
            if playlists.isEmpty {
                Text("Inga spellistor hittades.")
                    .foregroundStyle(.secondary)
            }
            ForEach(playlists) { playlist in
                Button { Task { await pick(playlist) } } label: {
                    HStack(spacing: 12) {
                        artwork(for: playlist)
                        VStack(alignment: .leading) {
                            Text(playlist.name)
                                .foregroundStyle(.primary)
                            Text("\(playlist.trackCount) låtar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func artwork(for playlist: SpotifyPlaylist) -> some View {
        if let url = playlist.imageURL {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "music.note.list").foregroundStyle(.secondary))
        }
    }

    // MARK: - Loading & selection

    private func loadIfPossible() async {
        guard spotify.accessToken != nil, phase == .idle else { return }
        await load()
    }

    private func load() async {
        guard let token = spotify.accessToken else { return }
        phase = .loading
        do {
            playlists = try await api.fetchPlaylists(token: token)
            phase = .loaded
        } catch {
            phase = .error(message(for: error))
        }
    }

    private func pick(_ playlist: SpotifyPlaylist) async {
        switch mode {
        case .playlistContext:
            onAdd([.spotify(uri: playlist.uri, name: playlist.name)])
            dismiss()
        case .expandTracks:
            importingName = playlist.name
            phase = .importing
            do {
                // Read tracks over the App Remote connection (content API), not the Web API —
                // the Web API's /playlists/{id}/tracks returns 403 with an App Remote token.
                let tracks = try await spotify.fetchPlaylistTracks(uri: playlist.uri)
                guard !tracks.isEmpty else {
                    phase = .error("Kunde inte läsa spellistans låtar. Kontrollera att Spotify är anslutet och försök igen.")
                    return
                }
                onAdd(tracks.map { .spotify(uri: $0.uri, name: $0.name) })
                dismiss()
            } catch {
                phase = .error(message(for: error))
            }
        }
    }

    private func message(for error: Error) -> String {
        switch error {
        case SpotifyWebAPIError.notConnected:
            return "Anslut Spotify på Spotify-fliken först, och försök sedan igen."
        case SpotifyWebAPIError.http(let status, _) where status == 401 || status == 403:
            return "Behörighet saknas. Koppla från och anslut Spotify igen på Spotify-fliken."
        default:
            return "Kunde inte hämta spellistor. Kontrollera nätverket och försök igen."
        }
    }
}
