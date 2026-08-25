import SwiftUI

/// Enlarged view of a single referee signal. Static signals show one photo; two-part
/// signals (e.g. Hooking) cross-fade between their two frames on a timer as a light
/// "animation" — the only motion the still-photo source supports.
struct RefereeSignalDetailView: View {
    let signal: RefereeSignal

    @Environment(ConfigStore.self) private var store
    @State private var frame = 0
    private let timer = Timer.publish(every: 0.9, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    ForEach(Array(signal.imageNames.enumerated()), id: \.offset) { index, name in
                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .opacity(index == frame ? 1 : 0)
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .animation(.easeInOut(duration: 0.4), value: frame)

                if signal.isAnimated {
                    Label("Tvådelat tecken – växlar automatiskt", systemImage: "arrow.triangle.2.circlepath")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(BrandBackground(accent: store.config.branding.accentColor))
        .navigationTitle("\(signal.number) \(signal.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            guard signal.isAnimated else { return }
            frame = (frame + 1) % signal.imageNames.count
        }
    }
}
