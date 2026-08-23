import SwiftUI
import UniformTypeIdentifiers

/// Edit an ordered playlist: add local MP3s or Spotify URIs, reorder, and delete.
/// Used for both the game playlist and the intermission playlist.
struct PlaylistEditorView: View {
    let title: String
    @Binding var resources: [AudioResource]
    var onChange: () -> Void

    @Environment(ConfigStore.self) private var store
    @State private var showImporter = false
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

                HStack {
                    TextField("spotify:playlist:… eller :track:", text: $spotifyURI)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Lägg till") {
                        let trimmed = spotifyURI.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        resources.append(.spotify(uri: trimmed))
                        onChange()
                        spotifyURI = ""
                    }
                    .disabled(spotifyURI.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
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
