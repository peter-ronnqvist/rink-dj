import SwiftUI
import UIKit

/// One large, colour-coded button on the Control screen. Deliberately big with an
/// icon, title and one-line hint so an official can hit the right one quickly during
/// fast play — and now with a chunky, physical press feel that reads clearly even
/// through gloves.
struct EventButton: View {
    let event: GameEvent
    var isActive: Bool = false
    let action: () -> Void

    /// Flemingsbergs IK yellow, used as the accent on the glossy dark style.
    static let fikYellow = Color(red: 1.0, green: 0.867, blue: 0.0) // #FFDD00

    /// EXPLORATORY: which events use the new slick black+yellow "Flemingsberg" style
    /// instead of a flat colour tile. Red (Avblåsning) and green (Täkning) keep their
    /// colours because they're the universally-understood stop/go signals; everything
    /// else gets the glossy look.
    private var isGlossy: Bool { event != .avblasning && event != .tekning }

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
        }
        .buttonStyle(PhysicalButtonStyle(isGlossy: isGlossy,
                                         tint: event.tint,
                                         isActive: isActive))
        .accessibilityLabel("\(event.title). \(event.subtitle)")
    }
}

/// A chunky, skeuomorphic key: the coloured cap sits on top of a darker "side wall"
/// that gives it visible thickness. Pressing sinks the cap down into the wall, dims
/// the glossy sheen and tightens the shadow — a big, unambiguous state change for
/// gloved hands on the bench.
private struct PhysicalButtonStyle: ButtonStyle {
    let isGlossy: Bool
    let tint: Color
    let isActive: Bool

    /// How much thickness the key has (and how far the cap travels when pressed).
    private let depth: CGFloat = 8
    private let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        // The visible cap: label + face + bevels, clipped to the rounded shape.
        let cap = configuration.label
            .foregroundStyle(isGlossy ? EventButton.fikYellow : .white)
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(face(pressed: pressed))
            .overlay { bevel(pressed: pressed) }
            .overlay { activeRing }
            .modifier(PressFlash(pressed: pressed, shape: shape))
            .clipShape(shape)

        cap
            // Coloured glow that lingers on the last-pressed button until the next tap.
            .shadow(color: isActive ? glowColor.opacity(0.9) : .clear,
                    radius: isActive ? 14 : 0)
            // Side wall: a darker copy peeking out below the cap gives real thickness.
            // When pressed the cap drops onto the wall, so almost none of it shows.
            .background {
                shape
                    .fill(wallColor)
                    .offset(y: pressed ? 1 : depth)
                    .shadow(color: .black.opacity(0.5),
                            radius: pressed ? 2 : 7,
                            y: pressed ? 1 : 5)
            }
            // The whole cap travels downward on press.
            .offset(y: pressed ? depth - 1 : 0)
            .animation(.spring(response: 0.14, dampingFraction: 0.62), value: pressed)
            // A firm buzz the instant the key goes down — the closure returns nil on
            // release so we only buzz on press, not twice per tap. Only felt on a real
            // device; the simulator has no haptics. Try swapping the style below.
            .sensoryFeedback(trigger: pressed) { _, isDown in
                isDown ? .impact(weight: .heavy, intensity: 1.0) : nil
            }
    }

    // MARK: - Pieces

    @ViewBuilder
    private func face(pressed: Bool) -> some View {
        if isGlossy {
            ZStack {
                LinearGradient(colors: [Color(white: 0.24), Color(white: 0.05)],
                               startPoint: .top, endPoint: .bottom)
                LinearGradient(colors: [EventButton.fikYellow.opacity(0.18), .clear],
                               startPoint: .bottom, endPoint: .center)
                // Glossy sheen across the top half — dims noticeably when pressed.
                LinearGradient(colors: [.white.opacity(pressed ? 0.10 : 0.32),
                                        .white.opacity(0.04), .clear],
                               startPoint: .top, endPoint: .center)
            }
        } else {
            ZStack {
                Rectangle().fill(tint.gradient)
                // A matching sheen so the coloured keys feel moulded too.
                LinearGradient(colors: [.white.opacity(pressed ? 0.08 : 0.28), .clear],
                               startPoint: .top, endPoint: .center)
            }
        }
    }

    /// Inner edge lighting: bright top lip + dark bottom lip = rounded, moulded cap.
    /// Both flatten when pressed so the cap looks like it's lying in the socket.
    private func bevel(pressed: Bool) -> some View {
        shape.strokeBorder(
            LinearGradient(
                colors: [.white.opacity(pressed ? 0.15 : 0.55),
                         .clear,
                         .black.opacity(pressed ? 0.35 : 0.22)],
                startPoint: .top, endPoint: .bottom),
            lineWidth: 1.5)
    }

    @ViewBuilder
    private var activeRing: some View {
        if isActive {
            // A bold, bright ring so the last-pressed key stays obvious at a glance.
            shape.strokeBorder(.white, lineWidth: 5)
                .overlay {
                    shape.inset(by: 3).strokeBorder(glowColor, lineWidth: 2)
                }
        }
    }

    /// The colour used for the active glow/ring — the key's own accent.
    private var glowColor: Color { isGlossy ? EventButton.fikYellow : tint }

    /// The colour of the button's side wall: a darker shade of the cap.
    private var wallColor: Color {
        isGlossy ? Color(red: 0.16, green: 0.13, blue: 0.0) // dark amber to match the FIK glow
                 : tint.darkened(by: 0.32)
    }
}

/// A bright bloom on the cap the instant it's pressed, fading out over a moment.
/// Because it's driven by a state change (not held opacity) it still flashes clearly
/// on a quick tap — the visual stand-in for a haptic buzz on iPad, which has no
/// Taptic Engine.
private struct PressFlash: ViewModifier {
    let pressed: Bool
    let shape: RoundedRectangle
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                shape.fill(.white).opacity(opacity).blendMode(.plusLighter)
            }
            .onChange(of: pressed) { _, isDown in
                if isDown {
                    opacity = 0.55
                    withAnimation(.easeOut(duration: 0.35)) { opacity = 0 }
                }
            }
    }
}

private extension Color {
    /// A darker shade of this colour, for skeuomorphic side walls / shadows.
    func darkened(by amount: Double) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h, saturation: s, brightness: max(0, b - amount), opacity: a)
    }
}

#Preview {
    ZStack {
        Color(white: 0.08).ignoresSafeArea()
        HStack(spacing: 12) {
            EventButton(event: .avblasning) {}
            EventButton(event: .icing) {}
            EventButton(event: .tekning) {}
        }
        .padding()
    }
}
