import SwiftUI

/// App entry point. Creates the two shared services (config store + playback
/// coordinator) once and injects them into the SwiftUI environment so every screen
/// can reach them — similar to registering singletons in a DI container.
@main
struct RinkDJApp: App {
    @State private var store = ConfigStore()
    @State private var coordinator = PlaybackCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(coordinator)
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
    }
}
