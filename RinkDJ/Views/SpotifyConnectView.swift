import SwiftUI

/// The Spotify screen: connect the app to the Spotify app on the device and show the
/// live connection status. Playback itself is driven from the Control screen via
/// `PlaybackCoordinator` → `SpotifyEngine`; this screen just handles the connection.
struct SpotifyConnectView: View {
    @Environment(SpotifyEngine.self) private var spotify

    var body: some View {
        Form {
            Section("Status") {
                if spotify.isConnected {
                    Label(spotify.statusMessage, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    if let now = spotify.nowPlaying {
                        Label(now, systemImage: "music.note")
                    }
                } else {
                    Label(spotify.statusMessage, systemImage: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                if let error = spotify.connectionError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            Section {
                if spotify.isConnected {
                    Button(role: .destructive) {
                        spotify.disconnect()
                    } label: {
                        Label("Koppla från", systemImage: "xmark.circle")
                    }
                } else {
                    Button {
                        spotify.authorize()
                    } label: {
                        Label("Anslut Spotify", systemImage: "music.note")
                    }
                }
            }

            Section {
                Label("Spotify Premium-konto", systemImage: "checkmark.seal")
                Label("Spotify-appen installerad", systemImage: "iphone")
                Label("En fysisk enhet (fungerar inte i simulatorn)", systemImage: "exclamationmark.triangle")
            } header: {
                Text("Krav")
            } footer: {
                Text("Ange Spotify-URI:er för händelser och spellistor i inställningarna. Anslut här för att styra uppspelningen i Spotify-appen under matchen.")
            }
        }
        .navigationTitle("Spotify")
        .navigationBarTitleDisplayMode(.inline)
    }
}
