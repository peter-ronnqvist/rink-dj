import SwiftUI

/// Placeholder for the Phase 2 Spotify connection screen. Explains the requirements
/// so it's clear why Spotify playback isn't active yet.
struct SpotifyConnectView: View {
    var body: some View {
        Form {
            Section {
                Label("Inte ansluten", systemImage: "xmark.circle")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Status")
            }

            Section {
                Text("Spotify-uppspelning läggs till i Fas 2 och kräver:")
                Label("Spotify Premium-konto", systemImage: "checkmark.seal")
                Label("Spotify-appen installerad", systemImage: "iphone")
                Label("En fysisk iPhone (fungerar inte i simulatorn)", systemImage: "exclamationmark.triangle")
            } header: {
                Text("Krav")
            } footer: {
                Text("Fram till dess spelas låtar från importerade MP3-filer. Du kan redan nu ange Spotify-URI:er i inställningarna – de sparas och används när Fas 2 aktiveras.")
            }
        }
        .navigationTitle("Spotify")
        .navigationBarTitleDisplayMode(.inline)
    }
}
