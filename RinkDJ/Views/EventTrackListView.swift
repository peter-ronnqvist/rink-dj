import SwiftUI
import UniformTypeIdentifiers

/// Edit the ordered list of tracks bound to one event. Each press of the event button on the
/// Match screen steps to the next track in this list (round-robin — see `PlaybackCoordinator`),
/// so a one-item list plays the same sound every time. Tracks can be app-bundled sounds,
/// imported MP3s, or Spotify tracks, mixed freely; each Spotify track keeps its own start offset.
struct EventTrackListView: View {
    let title: String
    @Binding var resources: [AudioResource]
    var onChange: () -> Void

    /// The bundled defaults for this event, if any. Offered as a one-tap restore so the shipped
    /// sound can be recovered even though the importer only browses user files.
    var defaultResources: [AudioResource] = []

    @Environment(ConfigStore.self) private var store
    @State private var showImporter = false
    @State private var showTrackPicker = false

    var body: some View {
        Form {
            listSection
            addSection
            restoreSection
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $showTrackPicker) {
            SpotifyPlaylistPickerView(mode: .pickTrack) { added in
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

    // MARK: Sections

    private var listSection: some View {
        Section {
            if resources.isEmpty {
                Text("Inga låtar ännu")
                    .foregroundStyle(.secondary)
            } else {
                // `ForEach($resources)` hands each row a binding, so a Spotify row can push an
                // editor that writes its start offset straight back into the array element.
                ForEach($resources) { $resource in
                    if case .spotify = resource {
                        NavigationLink {
                            SpotifyStartOffsetEditor(resource: $resource, onChange: onChange)
                        } label: {
                            trackRow(resource)
                        }
                    } else {
                        trackRow(resource)
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
            Text("Vid varje knapptryck spelas nästa låt i listan, sedan börjar den om från "
                 + "början. Dra för att ändra ordning, svep för att ta bort.")
        }
    }

    private var addSection: some View {
        Section {
            NavigationLink {
                BundledSoundListPicker(resources: $resources, onChange: onChange)
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
        } header: {
            Text("Lägg till")
        }
    }

    @ViewBuilder
    private var restoreSection: some View {
        if !defaultResources.isEmpty, resources != defaultResources {
            Section {
                Button {
                    resources = defaultResources
                    onChange()
                } label: {
                    Label("Återställ standardljud", systemImage: "arrow.uturn.backward")
                }
            }
        }
    }

    // MARK: Rows

    private func trackRow(_ resource: AudioResource) -> some View {
        HStack {
            Label(resource.displayName, systemImage: iconName(for: resource))
                .lineLimit(1)
            Spacer()
            Text(resource.sourceLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func iconName(for resource: AudioResource) -> String {
        switch resource {
        case .localFile: return "waveform"
        case .spotify:   return "music.note.list"
        }
    }
}

/// A small editor for a single Spotify track's start offset. Only Spotify streams can be
/// seeked, so this is reached only from Spotify rows. Rebuilds the bound resource with the new
/// `startMs` (a `0` clears it to `nil` so it plays from the start) and persists via `onChange`.
private struct SpotifyStartOffsetEditor: View {
    @Binding var resource: AudioResource
    var onChange: () -> Void

    var body: some View {
        Form {
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
        .navigationTitle(resource.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var startMsBinding: Binding<Int> {
        Binding(
            get: { resource.spotifyStartMs },
            set: { newValue in
                guard case .spotify(let uri, let name, _) = resource else { return }
                resource = .spotify(uri: uri, name: name, startMs: newValue > 0 ? newValue : nil)
                onChange()
            }
        )
    }
}

/// Lists the sounds bundled with the app, appending the tapped one to the event's list and
/// returning. Kept on its own screen because the list can be long.
private struct BundledSoundListPicker: View {
    @Binding var resources: [AudioResource]
    var onChange: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(FileStore.bundledAudioFileNames(), id: \.self) { name in
            Button {
                resources.append(.localFile(fileName: name))
                onChange()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "waveform")
                    Text(name).lineLimit(1)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .foregroundStyle(.primary)
        }
        .navigationTitle("Appens ljud")
        .navigationBarTitleDisplayMode(.inline)
    }
}
