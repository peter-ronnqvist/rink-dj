import SwiftUI

/// Editor for the Paus-spellista: a single Spotify playlist that Spotify plays and loops
/// during intermissions. Unlike the Match-spellista (many ordered tracks, MP3s allowed),
/// the pause only needs one whole Spotify playlist, so it holds at most one item.
struct IntermissionPlaylistView: View {
    let title: String
    @Binding var resources: [AudioResource]
    var onChange: () -> Void

    @State private var showPlaylistPicker = false

    var body: some View {
        Form {
            Section("Spellista") {
                if let playlist = resources.first {
                    HStack {
                        Label(playlist.displayName, systemImage: "music.note.list")
                            .lineLimit(1)
                        Spacer()
                        Text(playlist.sourceLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Ingen spellista vald")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Välj") {
                Button {
                    showPlaylistPicker = true
                } label: {
                    Label("Välj Spotify-spellista…", systemImage: "music.note.list")
                }

                if !resources.isEmpty {
                    Button(role: .destructive) {
                        resources.removeAll()
                        onChange()
                    } label: {
                        Label("Ta bort spellista", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPlaylistPicker) {
            // Keep the playlist whole and replace any prior pick — the Paus-spellista
            // holds exactly one Spotify playlist.
            SpotifyPlaylistPickerView(mode: .playlistContext) { added in
                resources = added
                onChange()
            }
        }
    }
}
