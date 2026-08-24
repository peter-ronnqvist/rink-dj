import SwiftUI
import UIKit

/// The main game-day screen: team header, a grid of big event buttons, and a
/// now-playing bar with a stop button. This is what the official looks at during a match.
struct ControlView: View {
    @Environment(ConfigStore.self) private var store
    @Environment(PlaybackCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(GameEvent.controlRows.enumerated()), id: \.offset) { _, row in
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
            Image(systemName: "music.note")
                .foregroundStyle(store.config.branding.accentColor)
            Text(coordinator.nowPlaying)
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
}
