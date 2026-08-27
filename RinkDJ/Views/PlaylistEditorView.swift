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
    @State private var showClearConfirm = false

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
                HStack {
                    Text("Låtar (\(resources.count))")
                    Spacer()
                    if !resources.isEmpty {
                        Button("Rensa", role: .destructive) { showClearConfirm = true }
                            .textCase(nil)
                            .font(.caption.bold())
                    }
                }
            } footer: {
                Text("Dra för att ändra ordning. Svep för att ta bort.")
            }

            Section {
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
            } header: {
                Text("Lägg till")
            } footer: {
                Text("En Spotify-spellista importeras högst 20 låtar i taget. "
                     + "Har du fler: dela upp spellistan i delar på max 20 låtar i Spotify "
                     + "och importera varje del – de läggs till efter varandra.")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .confirmationDialog("Rensa spellistan?", isPresented: $showClearConfirm,
                            titleVisibility: .visible) {
            Button("Rensa alla låtar", role: .destructive) {
                resources.removeAll()
                onChange()
            }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Alla låtar i spellistan tas bort.")
        }
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

    private func iconName(for resource: AudioResource) -> String {
        switch resource {
        case .localFile: return "waveform"
        case .spotify:   return "music.note.list"
        }
    }
}
