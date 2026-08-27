import SwiftUI
import UniformTypeIdentifiers

/// Edit an ordered playlist: add local MP3s or Spotify URIs, reorder, and delete.
/// Used for both the game playlist and the intermission playlist.
struct PlaylistEditorView: View {
    let title: String
    @Binding var resources: [AudioResource]
    var onChange: () -> Void
    /// How a picked Spotify playlist is added: expanded to tracks for the stepped
    /// Match-spellista, kept whole (looping) for the Paus-spellista.
    var spotifyMode: SpotifyPickMode

    @Environment(ConfigStore.self) private var store
    @State private var showImporter = false
    @State private var showPlaylistPicker = false
    @State private var spotifyURI = ""

    var body: some View {
        Form {
            Section {
                if resources.isEmpty {
                    Text("Inga låtar ännu")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(resources) { resource in
                        HStack {
                            Label(resource.displayName, systemImage: iconName(for: resource))
                                .lineLimit(1)
                            Spacer()
                            Text(resource.sourceLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        resources.remove(atOffsets: indexSet)
                        onChange()
                    }
                    .onMove { from, to in
                        resources.move(fromOffsets: from, toOffset: to)
                        onChange()
                    }
                }
            } header: {
                Text("Låtar (\(resources.count))")
            } footer: {
                Text("Dra för att ändra ordning. Svep för att ta bort.")
            }

            Section("Lägg till") {
                Button {
                    showImporter = true
                } label: {
                    Label("Importera MP3-filer…", systemImage: "square.and.arrow.down")
                }

                Button {
                    showPlaylistPicker = true
                } label: {
                    Label("Välj Spotify-spellista…", systemImage: "music.note.list")
                }
            }

            Section {
                HStack {
                    TextField("Klistra in Spotify-länk eller URI", text: $spotifyURI)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Lägg till") { addPastedSpotifyURI() }
                        .disabled(SpotifyURI.normalize(spotifyURI) == nil)
                }
            } header: {
                Text("Eller klistra in en länk")
            } footer: {
                Text("Stödjer både delningslänkar (open.spotify.com) och spotify:-URI:er.")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $showPlaylistPicker) {
            SpotifyPlaylistPickerView(mode: spotifyMode) { added in
                resources.append(contentsOf: added)
                onChange()
            }
        }
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [.audio],
                      allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                for url in urls {
                    if let imported = store.importAudio(from: url) {
                        resources.append(imported)
                    }
                }
                onChange()
            }
        }
    }

    /// Normalize the pasted text to a canonical `spotify:` URI before storing it, so a
    /// pasted open.spotify.com share link becomes something the SDK can actually play.
    private func addPastedSpotifyURI() {
        guard let uri = SpotifyURI.normalize(spotifyURI) else { return }
        resources.append(.spotify(uri: uri))
        onChange()
        spotifyURI = ""
    }

    private func iconName(for resource: AudioResource) -> String {
        switch resource {
        case .localFile: return "waveform"
        case .spotify:   return "music.note.list"
        }
    }
}
