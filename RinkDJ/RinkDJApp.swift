import SwiftUI

/// App entry point. Creates the shared services (config store, Spotify engine, playback
/// coordinator) once and injects them into the SwiftUI environment so every screen can
/// reach them — similar to registering singletons in a DI container.
@main
struct RinkDJApp: App {
    @State private var store = ConfigStore()
    @State private var spotify: SpotifyEngine
    @State private var coordinator: PlaybackCoordinator
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Build one SpotifyEngine and share it with both the coordinator (which routes
        // Spotify resources to it) and the environment (so the Spotify screen can drive
        // connect/disconnect on the same instance).
        let spotify = SpotifyEngine()
        _spotify = State(initialValue: spotify)
        _coordinator = State(initialValue: PlaybackCoordinator(engines: [LocalAudioEngine(), spotify]))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(coordinator)
                .environment(spotify)
                // OAuth redirect from the Spotify app comes back here.
                .onOpenURL { spotify.handle(url: $0) }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:     spotify.connectIfPossible()
            case .background: spotify.disconnect()
            default:          break
            }
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            ControlView()
                .tabItem { Label("Match", systemImage: "sportscourt.fill") }
            SetupView()
                .tabItem { Label("Inställningar", systemImage: "gearshape.fill") }
        }
        // The app uses a branded dark look everywhere, regardless of the phone's
        // light/dark setting — it's a game-day controller, not a general-purpose app.
        .preferredColorScheme(.dark)
    }
}
