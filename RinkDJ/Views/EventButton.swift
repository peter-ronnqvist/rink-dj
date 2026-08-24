import SwiftUI

/// One large, colour-coded button on the Control screen. Deliberately big with an
/// icon, title and one-line hint so an official can hit the right one quickly during
/// fast play.
struct EventButton: View {
    let event: GameEvent
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: event.systemImage)
                    .font(.system(size: 26, weight: .bold))
                Text(event.shortTitle)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(event.subtitle)
                    .font(.caption2)
                    .opacity(0.9)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(event.tint.gradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white, lineWidth: 4)
                }
            }
            .shadow(radius: isActive ? 8 : 2, y: 2)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact, trigger: isActive)
        .accessibilityLabel("\(event.title). \(event.subtitle)")
    }
}
