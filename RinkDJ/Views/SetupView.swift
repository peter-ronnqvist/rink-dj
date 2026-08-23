import SwiftUI

/// The Setup tab: configure team branding, the game & intermission playlists, and the
/// track bound to each special event. Everything is persisted via `ConfigStore`.
struct SetupView: View {
    @Environment(ConfigStore.self) private var store

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section("Lag") {
                    NavigationLink {
                        TeamBrandingView()
                    } label: {
                        HStack(spacing: 12) {
                            TeamLogoView(branding: store.config.branding, size: 32)
                            Text(store.config.branding.teamName)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        PlaylistEditorView(title: "Spellista",
                                           resources: $store.config.gamePlaylist,
                                           onChange: store.save)
                    } label: {
                        LabeledContent("Spellista",
                                       value: "\(store.config.gamePlaylist.count) låtar")
                    }
                    NavigationLink {
                        PlaylistEditorView(title: "Paus-spellista",
                                           resources: $store.config.intermissionPlaylist,
                                           onChange: store.save)
                    } label: {
                        LabeledContent("Paus-spellista",
                                       value: "\(store.config.intermissionPlaylist.count) låtar")
                    }
                } header: {
                    Text("Spellistor")
                } footer: {
                    Text("Vid varje avblåsning spelas nästa låt i spellistan. Pausen spelar paus-spellistan.")
                }

                Section("Händelselåtar") {
                    ForEach(GameEvent.configurableTrackEvents) { event in
                        NavigationLink {
                            ResourcePickerView(
                                title: event.title,
                                resource: bindingForTrack(of: event),
                                onChange: store.save
                            )
                        } label: {
                            LabeledContent(event.title) {
                                Text(store.config.track(for: event)?.displayName ?? "Ingen")
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Section("Spotify") {
                    NavigationLink {
                        SpotifyConnectView()
                    } label: {
                        LabeledContent("Anslutning", value: "Fas 2")
                    }
                }

                Section {
                    Button("Återställ till demo", role: .destructive) {
                        store.resetToDemo()
                    }
                }
            }
            .navigationTitle("Inställningar")
            .scrollContentBackground(.hidden)
            .background(BrandBackground(accent: store.config.branding.accentColor))
        }
    }

    /// A binding that reads/writes the track bound to a specific event and saves on change.
    private func bindingForTrack(of event: GameEvent) -> Binding<AudioResource?> {
        Binding(
            get: { store.config.track(for: event) },
            set: { store.config.setTrack($0, for: event); store.save() }
        )
    }
}
