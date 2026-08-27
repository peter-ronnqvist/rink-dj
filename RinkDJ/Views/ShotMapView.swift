import SwiftUI

/// The "Skottkarta" tab: a shot map drawn over the same rink as the Skott tally. Every shot
/// of the game is plotted as a dot, coloured by the period it was taken in. Because goalies
/// swap ends each period, positions are mirrored so all Hemma (home) shots attack the right
/// net and all Borta (away) shots the left — a per-team "where do we shoot from" map that
/// accumulates across the whole game (only "Ny match" on the Skott tab clears it).
struct ShotMapView: View {
    @Environment(ShotStore.self) private var shots
    @Environment(ConfigStore.self) private var store

    private var accent: Color { store.config.branding.accentColor }

    /// Distinct colour per period, matching the legend. Indices past overtime fall back to
    /// the accent so the map never crashes on unexpected data.
    static func periodColor(_ index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .green
        case 2: return .orange
        case 3: return .purple
        default: return .gray
        }
    }

    /// Canonical rink position (0…1) for a shot: Hemma → right net, Borta → left net. A tap
    /// on a net credits the attacking team, so the attacked end is `x >= 0.5`. When that
    /// isn't the team's canonical end we point-reflect (both axes — an end swap is a 180°
    /// rotation of play) so the cluster lands on the correct side.
    private func canonical(_ shot: Shot) -> CGPoint {
        let onRight = shot.x >= 0.5
        let needsFlip = shot.isHome ? !onRight : onRight
        return needsFlip ? CGPoint(x: 1 - shot.x, y: 1 - shot.y)
                         : CGPoint(x: shot.x, y: shot.y)
    }

    var body: some View {
        ZStack {
            BrandBackground(accent: accent)

            HockeyRinkView(accent: accent)
                .padding(8)

            // End labels naming which team's shots land at each net (matches the mirroring).
            GeometryReader { geo in
                endLabel("Borta")
                    .position(x: geo.size.width * 0.22, y: geo.size.height * 0.5)
                endLabel("Hemma")
                    .position(x: geo.size.width * 0.78, y: geo.size.height * 0.5)
            }
            .padding(8)
            .allowsHitTesting(false)

            // One dot per shot, at its canonical position, coloured by period. Padding
            // matches the rink and the Skott tap surface so dots line up with where taps
            // were made.
            GeometryReader { geo in
                ForEach(Array(shots.game.shots.enumerated()), id: \.offset) { _, shot in
                    let p = canonical(shot)
                    Circle()
                        .fill(Self.periodColor(shot.period).opacity(0.85))
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                        .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
                }
            }
            .padding(8)
            .allowsHitTesting(false)

            if shots.game.shots.isEmpty {
                Text("Inga skott registrerade ännu")
                    .font(.callout.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.35), in: Capsule())
            } else {
                VStack {
                    legend
                    Spacer()
                }
                .padding(20)
            }
        }
    }

    // MARK: - Pieces

    /// A period-colour legend, showing only the periods that actually have shots.
    private var legend: some View {
        HStack(spacing: 14) {
            ForEach(0..<ShotStore.maxPeriods, id: \.self) { i in
                if shots.periodTotals(i).home + shots.periodTotals(i).away > 0 {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Self.periodColor(i))
                            .frame(width: 10, height: 10)
                        Text(ShotStore.periodLabel(i))
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.black.opacity(0.35), in: Capsule())
    }

    private func endLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.heavy))
            .tracking(1)
            .foregroundStyle(.black)
    }
}
