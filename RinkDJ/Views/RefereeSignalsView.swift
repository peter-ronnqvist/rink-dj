import SwiftUI

/// The referee hand-signal (domartecken) reference, pushed from the Speaker tab. Shows
/// the signals grouped by category in a grid; tapping one opens its detail view. Built on
/// `ScrollView` + `GroupBox` over `BrandBackground` to match the rest of the app.
struct RefereeSignalsView: View {
    @Environment(ConfigStore.self) private var store

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(RefereeSignal.Category.allCases) { category in
                    GroupBox(category.rawValue) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(RefereeSignal.signals(in: category)) { signal in
                                NavigationLink {
                                    RefereeSignalDetailView(signal: signal)
                                } label: {
                                    SignalCard(signal: signal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Text("Domartecken: mskold.se")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .background(BrandBackground(accent: store.config.branding.accentColor))
        .navigationTitle("Domartecken")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A grid tile for one signal: the photo on a white rounded card, with the rule number
/// and name shown as a caption below (the names are no longer printed in the images).
private struct SignalCard: View {
    let signal: RefereeSignal

    var body: some View {
        VStack(spacing: 4) {
            Image(signal.imageNames[0])
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .topTrailing) {
                    if signal.isAnimated {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(.white, .black.opacity(0.5))
                            .padding(6)
                    }
                }
            Text("\(signal.number) \(signal.name)")
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(signal.number) \(signal.name)")
    }
}
