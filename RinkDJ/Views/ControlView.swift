import SwiftUI
import UIKit

/// The main game-day screen: team header, a grid of big event buttons, and a
/// now-playing bar with a stop button. This is what the official looks at during a match.
struct ControlView: View {
    @Environment(ConfigStore.self) private var store
    @Environment(PlaybackCoordinator.self) private var coordinator
    @Environment(SpotifyEngine.self) private var spotify
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(GameEvent.controlRows(advanced: store.config.isAdvanced).enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 10) {
                            ForEach(row) { event in
                                EventButton(event: event, isActive: coordinator.lastEvent == event) {
                                    coordinator.handle(event, config: store.config)
                                }
                            }
                        }
                    }
                }
                .padding(10)
            }

            nowPlayingBar
        }
        .background(BrandBackground(accent: store.config.branding.accentColor))
    }

    private var header: some View {
        HStack(spacing: 12) {
            TeamLogoView(branding: store.config.branding, size: 40)
            VStack(alignment: .leading, spacing: 0) {
                Text(store.config.branding.teamName)
                    .font(.headline)
                Text("Matchljud")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var nowPlayingBar: some View {
        HStack(spacing: 12) {
            nowPlayingSourceMark
            Text(nowPlayingText)
                .font(.subheadline)
                .lineLimit(1)
            Spacer()
            Button(role: .destructive) {
                coordinator.stop()
            } label: {
                Label("Stopp", systemImage: "stop.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    /// Text for the now-playing bar. For Spotify tracks we prefer the real "Title – Artist"
    /// metadata reported by the SDK (populated on-device via the player-state callback),
    /// falling back to the coordinator's contextual label (e.g. before metadata arrives,
    /// or in the Simulator where Spotify can't play).
    private var nowPlayingText: String {
        if case .spotify = coordinator.nowPlayingResource, let metadata = spotify.nowPlaying {
            return metadata
        }
        return coordinator.nowPlaying
    }

    /// The leading mark in the now-playing bar. For Spotify tracks this is the official
    /// full Spotify logo (required brand attribution for the metadata shown), and tapping
    /// it opens the track in the Spotify app (required link-back). Local files keep a
    /// generic note icon.
    @ViewBuilder
    private var nowPlayingSourceMark: some View {
        if case .spotify(let uri) = coordinator.nowPlayingResource {
            Button {
                if let url = URL(string: uri) { openURL(url) }
            } label: {
                Image("SpotifyFullLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .accessibilityLabel("Spela i Spotify")
            }
            .buttonStyle(.plain)
        } else {
            Image(systemName: "music.note")
                .foregroundStyle(store.config.branding.accentColor)
        }
    }
}
