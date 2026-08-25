import SwiftUI

/// The Speaker tab: reference material for the arena announcer ("speaker") — instruction
/// tips, plus a link through to the referee hand-signal (domartecken) reference. Built on
/// `ScrollView` + `GroupBox` over `BrandBackground` (like `SetupView`) so it scrolls
/// correctly under the iOS 26 floating `TabView`.
struct SpeakerView: View {
    @Environment(ConfigStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GroupBox {
                        NavigationLink {
                            RefereeSignalsView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundStyle(store.config.branding.accentColor)
                                Text("Domartecken")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                            .foregroundStyle(.primary)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }

                    GroupBox("Tips till speakern") {
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(SpeakerTip.all) { tip in
                                SpeakerTipView(tip: tip)
                            }
                        }
                        .padding(.top, 4)
                    }
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
