import SwiftUI

/// The Speaker tab: reference material for the arena announcer ("speaker") — instruction
/// tips plus the referee hand signals (domartecken) grouped by category. Built on
/// `ScrollView` + `GroupBox` over `BrandBackground` (like `SetupView`) so it scrolls
/// correctly under the iOS 26 floating `TabView`.
struct SpeakerView: View {
    @Environment(ConfigStore.self) private var store

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GroupBox("Tips till speakern") {
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(SpeakerTip.all) { tip in
                                SpeakerTipView(tip: tip)
                            }
                        }
                        .padding(.top, 4)
                    }

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
            .navigationTitle("Speaker")
        }
    }
}

/// One announcer tip: title, instruction, and (for announcements) a phrasing template
/// and worked examples.
private struct SpeakerTipView: View {
    let tip: SpeakerTip

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tip.title)
                .font(.headline)
            Text(tip.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let format = tip.format {
                Text(format)
                    .font(.callout)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }

            if !tip.examples.isEmpty {
                Text("Exempel")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
                ForEach(tip.examples, id: \.self) { example in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "quote.opening")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(example)
                            .font(.callout)
                            .italic()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
