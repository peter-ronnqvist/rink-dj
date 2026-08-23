import SwiftUI
import UniformTypeIdentifiers

/// Assign a single audio resource to an event: pick a local MP3 (works today) or
/// enter a Spotify URI (stored now, playable in Phase 2).
struct ResourcePickerView: View {
    let title: String
    @Binding var resource: AudioResource?
    var onChange: () -> Void

    /// The bundled default for this event, if any. Offered as a one-tap restore so the
    /// shipped sound can be recovered even though the importer only browses user files.
    var defaultResource: AudioResource? = nil

    @Environment(ConfigStore.self) private var store
    @State private var showImporter = false
    @State private var spotifyURI = ""

    var body: some View {
        Form {
            Section("Nuvarande låt") {
                if let current = resource {
                    HStack {
                        Label(current.displayName, systemImage: iconName(for: current))
                            .lineLimit(1)
                        Spacer()
                        Text(current.sourceLabel)
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

                if let def = defaultResource, resource != def {
                    Button {
                        resource = def
                        onChange()
                    } label: {
                        Label("Återställ standardljud (\(def.displayName))",
                              systemImage: "arrow.uturn.backward")
                    }
                }
            }

            Section("Byt låt") {
                NavigationLink {
                    BundledSoundPickerView(resource: $resource, onChange: onChange)
                } label: {
                    Label("Välj från appens ljud", systemImage: "waveform")
                }
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

/// A dedicated screen listing the sounds bundled with the app, so the main picker stays
/// compact. Tapping a sound assigns it and returns. Kept on its own screen because the
/// list can be long and would otherwise push the picker's other actions off-screen.
private struct BundledSoundPickerView: View {
    @Binding var resource: AudioResource?
    var onChange: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(FileStore.bundledAudioFileNames(), id: \.self) { name in
            Button {
                resource = .localFile(fileName: name)
                onChange()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "waveform")
                    Text(name).lineLimit(1)
                    Spacer()
                    if resource == .localFile(fileName: name) {
                        Image(systemName: "checkmark").foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
            }
            .foregroundStyle(.primary)
        }
        .navigationTitle("Appens ljud")
        .navigationBarTitleDisplayMode(.inline)
    }
}
