import SwiftUI

/// The Setup tab: configure team branding, the game & intermission playlists, and the
/// track bound to each special event. Everything is persisted via `ConfigStore`.
///
/// Built on a `ScrollView` + `GroupBox` cards rather than a `Form`: under the iOS 26
/// floating `TabView`, a `Form`/`List` inside a `NavigationStack` fails to scroll
/// (it takes unbounded height), so its lower rows end up stuck behind the tab bar. A
/// plain `ScrollView` scrolls correctly and insets above the floating bar.
struct SetupView: View {
    @Environment(ConfigStore.self) private var store
    @Environment(SpotifyEngine.self) private var spotify

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    modeSection(store: store)
                    playlistSection
                    eventSection(store: store)
                    spotifySection
                    resetSection
                }
                .padding()
                .buttonStyle(.plain)
            }
            .background(BrandBackground(accent: store.config.branding.accentColor))
            .navigationTitle("Inställningar")
        }
    }

    // MARK: Sections

    private func modeSection(store: ConfigStore) -> some View {
        GroupBox("Läge") {
            Toggle("Avancerad", isOn: Binding(
                get: { store.config.isAdvanced },
                set: { store.config.isAdvanced = $0; store.save() }
            ))
            footer("I avancerat läge visas alla knappar på matchskärmen. Annars visas "
                   + "endast Avblåsning, Tekning, Hemmamål, Bortamål, Paus och Matchslut.")
        }
    }

    private var playlistSection: some View {
        GroupBox("Spellistor") {
            NavigationLink {
                PlaylistEditorView(title: "Spellista",
                                   resources: playlistBinding(\.gamePlaylist),
                                   onChange: store.save,
                                   spotifyMode: .expandTracks)
            } label: {
                row { labeled("Match-spellista", "\(store.config.gamePlaylist.count) låtar") }
            }
            Divider()
            NavigationLink {
                PlaylistEditorView(title: "Paus-spellista",
                                   resources: playlistBinding(\.intermissionPlaylist),
                                   onChange: store.save,
                                   spotifyMode: .playlistContext)
            } label: {
                row { labeled("Paus-spellista", "\(store.config.intermissionPlaylist.count) låtar") }
            }
            footer("Vid varje avblåsning spelas nästa låt i spellistan. Pausen spelar paus-spellistan.")
        }
    }

    private func eventSection(store: ConfigStore) -> some View {
        GroupBox("Händelselåtar") {
            ForEach(GameEvent.configurableTrackEvents) { event in
                NavigationLink {
                    ResourcePickerView(
                        title: event.title,
                        resource: bindingForTrack(of: event),
                        onChange: store.save,
                        defaultResource: AppConfig.defaultTrack(for: event)
                    )
                } label: {
                    row {
                        labeled(event.title,
                                store.config.track(for: event)?.displayName ?? "Ingen")
                    }
                }
                Divider()
            }
            Button {
                store.restoreDefaultEventSounds()
            } label: {
                row {
                    Label("Återställ standardljud", systemImage: "arrow.uturn.backward")
                    Spacer()
                }
            }
            .foregroundStyle(.primary)
            footer("Återställ standardljud sätter tillbaka alla händelseljud till appens "
                   + "original, utan att ändra spellistor eller lagprofil.")
        }
    }

    private var spotifySection: some View {
        GroupBox {
            NavigationLink {
                SpotifyConnectView()
            } label: {
                row { labeled("Anslutning", spotify.isConnected ? "Ansluten" : "Inte ansluten") }
            }
        } label: {
            // Official Spotify logo (unmodified) instead of a plain "Spotify" text label.
            Image("SpotifyFullLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 21)
                .accessibilityLabel("Spotify")
        }
    }

    private var resetSection: some View {
        GroupBox {
            Button(role: .destructive) {
                store.resetToDemo()
            } label: {
                Text("Återställ till demo")
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Row helpers

    /// A tappable row: content on the left, a chevron on the right, full-width hit area.
    private func row<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 12) {
            content()
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .foregroundStyle(.primary)
        .padding(.vertical, 6)
    }

    /// A title with a trailing secondary value, like Form's LabeledContent.
    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func footer(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    // MARK: Bindings

    private func playlistBinding(
        _ keyPath: WritableKeyPath<AppConfig, [AudioResource]>
    ) -> Binding<[AudioResource]> {
        Binding(
            get: { store.config[keyPath: keyPath] },
            set: { store.config[keyPath: keyPath] = $0; store.save() }
        )
    }

    /// A binding that reads/writes the track bound to a specific event and saves on change.
    private func bindingForTrack(of event: GameEvent) -> Binding<AudioResource?> {
        Binding(
            get: { store.config.track(for: event) },
            set: { store.config.setTrack($0, for: event); store.save() }
        )
    }
}
