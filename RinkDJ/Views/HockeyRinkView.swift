import SwiftUI

/// A hockey rink drawn with SwiftUI (no bitmap): white ice, red/blue lines, faceoff
/// circles and goal creases. Purely decorative — shared by the Skott tally tab
/// (`ShotsView`, which lays tap handling over it) and the Skottkarta map (`ShotMapView`,
/// which plots dots over it) so both show the exact same rink.
struct HockeyRinkView: View {
    var accent: Color

    private let red = Color(red: 0.85, green: 0.15, blue: 0.15)
    private let blue = Color(red: 0.10, green: 0.45, blue: 0.85)

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let inset = h * 0.04
            let rink = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
            let corner = rink.height * 0.20

            // Ice surface + boards.
            let boards = Path(roundedRect: rink, cornerRadius: corner)
            context.fill(boards, with: .color(Color(white: 0.97)))
            context.stroke(boards, with: .color(Color(white: 0.55)), lineWidth: rink.height * 0.02)

            let lineW = rink.height * 0.012

            // Goal lines (red) near each end.
            for gx in [rink.minX + rink.width * 0.07, rink.maxX - rink.width * 0.07] {
                context.stroke(verticalLine(x: gx, in: rink), with: .color(red.opacity(0.8)), lineWidth: lineW)
                // Goal crease.
                let crease = CGRect(x: gx - rink.width * 0.02, y: rink.midY - rink.height * 0.06,
                                    width: rink.width * 0.04, height: rink.height * 0.12)
                context.fill(Path(roundedRect: crease, cornerRadius: crease.width * 0.4),
                             with: .color(blue.opacity(0.20)))
            }

            // Blue lines.
            for bx in [rink.minX + rink.width * 0.33, rink.maxX - rink.width * 0.33] {
                context.stroke(verticalLine(x: bx, in: rink), with: .color(blue.opacity(0.85)),
                               lineWidth: lineW * 2)
            }

            // Center red line (dashed) + center circle + dot.
            context.stroke(verticalLine(x: rink.midX, in: rink), with: .color(red),
                           style: StrokeStyle(lineWidth: lineW * 2, dash: [rink.height * 0.05]))
            let cr = rink.height * 0.15
            context.stroke(circle(center: CGPoint(x: rink.midX, y: rink.midY), radius: cr),
                           with: .color(blue.opacity(0.85)), lineWidth: lineW)
            context.fill(circle(center: CGPoint(x: rink.midX, y: rink.midY), radius: rink.height * 0.02),
                         with: .color(red))

            // Four faceoff circles.
            let fr = rink.height * 0.13
            for fx in [rink.minX + rink.width * 0.20, rink.maxX - rink.width * 0.20] {
                for fy in [rink.midY - rink.height * 0.22, rink.midY + rink.height * 0.22] {
                    context.stroke(circle(center: CGPoint(x: fx, y: fy), radius: fr),
                                   with: .color(red.opacity(0.8)), lineWidth: lineW)
                    context.fill(circle(center: CGPoint(x: fx, y: fy), radius: rink.height * 0.015),
                                 with: .color(red.opacity(0.8)))
                }
            }
        }
    }

    private func verticalLine(x: CGFloat, in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: x, y: rect.minY))
            p.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
    }

    private func circle(center: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                               width: radius * 2, height: radius * 2))
    }
}
