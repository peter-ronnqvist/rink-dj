import SwiftUI
import UniformTypeIdentifiers

/// Assign a single audio resource to an event: pick a local MP3 (works today) or
/// enter a Spotify URI (stored now, playable in Phase 2).
struct ResourcePickerView: View {
    let title: String
    @Binding var resource: AudioResource?
    var onChange: () -> Void

    @Environment(ConfigStore.self) private var store
    @State private var showImporter = false
    @State private var spotifyURI = ""

    var body: some View {
        Form {
            Section("Nuvarande låt") {
                if let resource {
                    HStack {
                        Label(resource.displayName, systemImage: iconName(for: resource))
                            .lineLimit(1)
                        Spacer()
                        Text(resource.sourceLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Ta bort", role: .destructive) {
                        resource = nil
                        onChange()
                    }
                } else {
                    Text("Ingen låt vald")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Välj MP3-fil") {
                Button {
                    showImporter = true
                } label: {
                    Label("Importera ljudfil…", systemImage: "square.and.arrow.down")
                }
            }

            Section {
                TextField("spotify:track:…", text: $spotifyURI)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Använd Spotify-låt") {
                    let trimmed = spotifyURI.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    resource = .spotify(uri: trimmed)
                    onChange()
                    spotifyURI = ""
                }
                .disabled(spotifyURI.trimmingCharacters(in: .whitespaces).isEmpty)
            } header: {
                Text("Spotify (Fas 2)")
            } footer: {
                Text("Spotify-uppspelning aktiveras i Fas 2 på en fysisk enhet med Premium.")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [.audio],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result,
               let url = urls.first,
               let imported = store.importAudio(from: url) {
                resource = imported
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
