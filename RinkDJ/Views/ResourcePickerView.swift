import SwiftUI
import UniformTypeIdentifiers

/// Assign a single audio resource to an event: pick a local MP3, an app-bundled sound,
/// or a Spotify track chosen from one of the user's playlists.
struct ResourcePickerView: View {
    let title: String
    @Binding var resource: AudioResource?
    var onChange: () -> Void

    /// The bundled default for this event, if any. Offered as a one-tap restore so the
    /// shipped sound can be recovered even though the importer only browses user files.
    var defaultResource: AudioResource? = nil

    @Environment(ConfigStore.self) private var store
    @State private var showImporter = false
    @State private var showTrackPicker = false

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

            // Only Spotify streams can be seeked, so this is hidden for local files.
            if case .spotify = resource {
                Section {
                    HStack {
                        Text("Starta från (ms)")
                        Spacer()
                        TextField("0", value: startMsBinding, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                } footer: {
                    Text("Hoppar in i Spotify-låten vid den här tiden i millisekunder "
                         + "(t.ex. 30000 = 30 s). 0 spelar från början.")
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
                Button {
                    showTrackPicker = true
                } label: {
                    Label("Välj Spotify-låt…", systemImage: "music.note")
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTrackPicker) {
            SpotifyPlaylistPickerView(mode: .pickTrack) { added in
                if let track = added.first {
                    resource = track
                    onChange()
                }
            }
        }
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

    /// Reads/writes the Spotify start offset by rebuilding the resource with the same
    /// uri/name and the new `startMs`, then persisting via `onChange`. A `0` clears the
    /// offset (stored as `nil`) so it plays from the start.
    private var startMsBinding: Binding<Int> {
        Binding(
            get: { resource?.spotifyStartMs ?? 0 },
            set: { newValue in
                guard case .spotify(let uri, let name, _) = resource else { return }
                resource = .spotify(uri: uri, name: name, startMs: newValue > 0 ? newValue : nil)
                onChange()
            }
        )
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
