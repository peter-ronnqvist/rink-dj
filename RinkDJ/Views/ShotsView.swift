import SwiftUI

/// The "Skott" tab: a landscape shots-on-goal counter. One person turns the phone 90° and
/// taps each goal end to tally that team's shots. Counts are kept per period; advancing the
/// period (center) locks the previous period's totals. Discreet minus buttons correct
/// mis-taps, "Visa" shows the running result without touching the data, and "Ny match"
/// resets to Period 1. State lives in `ShotStore` (persisted).
struct ShotsView: View {
    @Environment(ShotStore.self) private var shots
    @Environment(ConfigStore.self) private var store

    @State private var confirmNextPeriod = false
    @State private var confirmNewGame = false
    @State private var showRules = false
    @State private var showSummary = false

    private var accent: Color { store.config.branding.accentColor }

    /// Which end the home goalie defends this period. Starts from `homeStartsLeft` (a tap
    /// on the centre faceoff dot flips it) and alternates every period. Everything that
    /// depends on side (badges, tap targets, which counter sits where) derives from this.
    private var homeGoalieLeft: Bool {
        (shots.game.currentIndex % 2 == 0) == homeStartsLeft
    }

    /// Which end the home bench (and thus the home goalie's starting end) is on. Fixed for
    /// the game; the centre-faceoff toggle flips it.
    private var homeStartsLeft: Bool { shots.game.homeStartsLeft }

    var body: some View {
        ZStack {
            BrandBackground(accent: accent)

            HockeyRinkView(accent: accent, branding: store.config.branding)
                .padding(8)

            // Zone labels on the ice at each zone's faceoff spots, naming the shots you
            // register by tapping that end. A tap credits the attacking team (opposite the
            // goalie), so the labels swap ends with the goalies each period.
            GeometryReader { geo in
                zoneLabel(homeGoalieLeft ? "Bortaskott" : "Hemmaskott")
                    .position(x: geo.size.width * 0.22, y: geo.size.height * 0.5)
                zoneLabel(homeGoalieLeft ? "Hemmaskott" : "Bortaskott")
                    .position(x: geo.size.width * 0.78, y: geo.size.height * 0.5)
            }
            .allowsHitTesting(false)

            // Tap surface over the whole rink. A tap is a shot ON the goal at that end, so
            // it credits the *attacking* team — the opposite of the goalie standing there.
            // The tap's position (normalized to the rink) is stored so the Skottkarta tab
            // can plot it. Padding matches HockeyRinkView so coords line up with the rink.
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { point in
                        let nx = point.x / geo.size.width
                        let ny = point.y / geo.size.height
                        let leftHalf = nx < 0.5
                        let isHome = leftHalf ? !homeGoalieLeft : homeGoalieLeft
                        shots.addShot(isHome: isHome, x: nx, y: ny)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
            }
            .padding(8)

            // Foreground controls capture their own taps (they sit above the tap zones).
            // Each team's counter sits above the goal it is attacking, so it swaps sides
            // with the goalies each period.
            VStack {
                HStack(alignment: .top) {
                    teamCounter(isHome: !homeGoalieLeft)
                    Spacer()
                    periodControl
                    Spacer()
                    teamCounter(isHome: homeGoalieLeft)
                }
                Spacer()
                HStack {
                    minusButton(action: homeGoalieLeft ? shots.removeAway : shots.removeHome)
                    Spacer()
                    HStack(spacing: 16) {
                        infoButton
                        summaryButton
                        newGameButton
                    }
                    Spacer()
                    minusButton(action: homeGoalieLeft ? shots.removeHome : shots.removeAway)
                }
            }
            .padding(20)

            // Centre faceoff dot: overrides which end the teams start on (by default the
            // home team attacks to the right). Small and central so it isn't hit by
            // accident during play.
            faceoffToggle
        }
        .confirmationDialog("Avsluta period \(shots.currentPeriodLabel)?", isPresented: $confirmNextPeriod, titleVisibility: .visible) {
            Button("Nästa period") {
                shots.nextPeriod()
                showSummary = true
            }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Periodens skott låses och kan inte längre ändras.")
        }
        .confirmationDialog("Avsluta matchen?", isPresented: $confirmNewGame, titleVisibility: .visible) {
            Button("Ny match", role: .destructive) { shots.newGame() }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Alla skott nollställs och perioden återställs till 1.")
        }
        .sheet(isPresented: $showRules) {
            ShotRulesView(accent: accent)
        }
        .sheet(isPresented: $showSummary) {
            ShotSummaryView(accent: accent)
        }
    }

    // MARK: - Pieces

    /// The counter for one team (Hemma or Borta), placed above the goal it is attacking.
    private func teamCounter(isHome: Bool) -> some View {
        counter(label: isHome ? "Hemma" : "Borta",
                current: isHome ? shots.currentHome : shots.currentAway,
                locked: shots.lockedPeriods(home: isHome))
    }

    /// The centre faceoff dot, tappable to swap the teams' starting ends.
    private var faceoffToggle: some View {
        Button {
            shots.swapStartingSides()
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.callout.bold())
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
    }

    /// Black text on the ice naming which team's shots a tap in that zone registers.
    private func zoneLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.heavy))
            .tracking(1)
            .foregroundStyle(.black)
    }

    /// Big current-period count, with each completed (locked) period listed small below
    /// as "1: 12". The big number resets to 0 when the period is advanced.
    private func counter(label: String, current: Int, locked: [(index: Int, label: String, count: Int)]) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("\(current)")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(accent)
                .monospacedDigit()
            ForEach(locked, id: \.index) { period in
                Text("\(period.label): \(period.count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }

    private var periodControl: some View {
        Button {
            if shots.canAdvancePeriod { confirmNextPeriod = true }
        } label: {
            VStack(spacing: 2) {
                Text("Period")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text(shots.currentPeriodLabel)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                if shots.canAdvancePeriod {
                    Label("Nästa", systemImage: "chevron.right")
                        .font(.caption2.bold())
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.black.opacity(0.35), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!shots.canAdvancePeriod)
    }

    /// Deliberately small and low-contrast so it isn't hit by accident during play.
    private func minusButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "minus.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
                .opacity(0.5)
        }
        .buttonStyle(.plain)
    }

    /// Opens the "what counts as a shot on goal" rules sheet. Styled to match the
    /// discreet "Ny match" pill next to it.
    private var infoButton: some View {
        Button {
            showRules = true
        } label: {
            Label("Regler", systemImage: "info.circle")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black.opacity(0.35), in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    /// Shows the running match result without changing any data. Styled like the discreet
    /// pills next to it.
    private var summaryButton: some View {
        Button {
            showSummary = true
        } label: {
            Label("Visa", systemImage: "magnifyingglass")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black.opacity(0.35), in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    private var newGameButton: some View {
        Button {
            confirmNewGame = true
        } label: {
            Label("Ny match", systemImage: "arrow.counterclockwise")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black.opacity(0.35), in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}

/// Reference sheet explaining what does and doesn't count as a shot on goal, shown from
/// the "Regler" button in `ShotsView`. Uses `ScrollView` + `GroupBox` (not `Form`/`List`)
/// so it scrolls reliably inside the app's floating `TabView`.
private struct ShotRulesView: View {
    var accent: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section(
                        title: "Vad som räknas som skott på mål",
                        systemImage: "checkmark.circle.fill",
                        tint: .green,
                        rules: [
                            ("Mål", "Alla puckar som går i mål registreras som skott."),
                            ("Målvaktsräddningar", "Skott som målvakten räddar, men som annars skulle ha gått in i målet."),
                            ("Returer", "Varje nytt avslut efter en retur som uppfyller kriterierna räknas som ett eget skott."),
                        ]
                    )
                    section(
                        title: "Vad som INTE räknas som skott på mål",
                        systemImage: "xmark.circle.fill",
                        tint: .red,
                        rules: [
                            ("Ramträffar", "Skott som tar i stolpen eller ribban räknas inte."),
                            ("Utanför", "Skott som går utanför målramen och plockas av målvakten (om pucken tydligt var på väg utanför)."),
                            ("Rensningar", "En misslyckad passning eller en ren rensning från egen zon som råkar gå mot mål räknas inte."),
                            ("Utespelarblockeringar", "Skott som stoppas av en utespelare (täckta skott) räknas inte i målvaktens statistik över skott på mål."),
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle("Skott på mål")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar") { dismiss() }
                }
            }
        }
    }

    private func section(title: String, systemImage: String, tint: Color,
                         rules: [(term: String, text: String)]) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(rules, id: \.term) { rule in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .foregroundStyle(accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.term)
                                .font(.subheadline.bold())
                            Text(rule.text)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
        }
    }
}

/// Non-destructive match result, shown from the "Visa" button in `ShotsView`. Displays the
/// running Hemma–Borta shot totals and a per-period breakdown without changing any data
/// (unlike "Ny match", which resets). Uses `ScrollView` + `GroupBox` (not `Form`/`List`) so
/// it scrolls reliably inside the app's floating `TabView`.
private struct ShotSummaryView: View {
    var accent: Color
    @Environment(ShotStore.self) private var shots
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    scoreboard
                    periodBreakdown
                }
                .padding()
            }
            .navigationTitle("Skottstatistik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar") { dismiss() }
                }
            }
        }
    }

    /// Big Hemma vs Borta totals across the whole game.
    private var scoreboard: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            teamTotal(label: "Hemma", value: shots.homeTotal)
            Text("–")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            teamTotal(label: "Borta", value: shots.awayTotal)
        }
        .frame(maxWidth: .infinity)
    }

    private func teamTotal(label: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(accent)
                .monospacedDigit()
        }
    }

    /// One row per played period: label, Hemma count, Borta count.
    private var periodBreakdown: some View {
        GroupBox {
            VStack(spacing: 10) {
                ForEach(0..<shots.playedPeriodCount, id: \.self) { i in
                    let totals = shots.periodTotals(i)
                    HStack {
                        Text(ShotStore.periodLabel(i))
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(totals.home)")
                            .frame(minWidth: 36, alignment: .trailing)
                            .monospacedDigit()
                        Text("–")
                            .foregroundStyle(.secondary)
                        Text("\(totals.away)")
                            .frame(minWidth: 36, alignment: .leading)
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        } label: {
            Label("Per period (Hemma–Borta)", systemImage: "list.number")
                .font(.headline)
        }
    }
}
