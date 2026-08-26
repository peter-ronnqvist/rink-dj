import Foundation
import Observation

/// Shots-on-goal tally for the current game. One `PeriodShots` per period played; only
/// the last (current) period is editable — advancing the period appends a fresh one and
/// thereby "locks" the earlier totals. `@Observable` (iOS 17+) so the Skott view binds to
/// it, and it persists to a single JSON file in Documents like `ConfigStore`.
@Observable
final class ShotStore {
    var game: ShotGame

    /// Standard hockey: three periods plus overtime. `currentIndex` can reach 3 (OT).
    static let maxPeriods = 4

    init() {
        self.game = Self.load() ?? ShotGame()
    }

    // MARK: - Mutations (each persists)

    func addHome() { current.home += 1; save() }
    func addAway() { current.away += 1; save() }

    /// Correct a mis-tap. Clamped at zero and only affects the current (editable) period.
    func removeHome() { current.home = max(0, current.home - 1); save() }
    func removeAway() { current.away = max(0, current.away - 1); save() }

    /// Lock the current period and start the next one. No-op once at overtime.
    func nextPeriod() {
        guard canAdvancePeriod else { return }
        game.periods.append(PeriodShots())
        game.currentIndex = game.periods.count - 1
        save()
    }

    /// Reset everything back to an empty Period 1.
    func newGame() {
        game = ShotGame()
        save()
    }

    /// Override the default starting orientation — swap which end each goalie starts on.
    /// Only affects which side is shown; the per-team tallies are unchanged.
    func swapStartingSides() {
        game.homeStartsLeft.toggle()
        save()
    }

    // MARK: - Derived values for the UI

    var homeTotal: Int { game.periods.reduce(0) { $0 + $1.home } }
    var awayTotal: Int { game.periods.reduce(0) { $0 + $1.away } }

    /// Shots in the current (editable) period — the big number the taps drive.
    var currentHome: Int { game.periods[game.currentIndex].home }
    var currentAway: Int { game.periods[game.currentIndex].away }

    var canAdvancePeriod: Bool { game.periods.count < Self.maxPeriods }

    /// Label for a period index: "1", "2", "3", then "Förlängning" (overtime).
    static func periodLabel(_ index: Int) -> String {
        index < 3 ? "\(index + 1)" : "Förlängning"
    }

    var currentPeriodLabel: String { Self.periodLabel(game.currentIndex) }

    /// The completed (locked) periods before the current one, for one side, as
    /// (period label, count) pairs — shown small under the big current-period number.
    func lockedPeriods(home: Bool) -> [(index: Int, label: String, count: Int)] {
        guard game.currentIndex > 0 else { return [] }
        return (0..<game.currentIndex).map { i in
            let p = game.periods[i]
            return (i, Self.periodLabel(i), home ? p.home : p.away)
        }
    }

    // MARK: - Editable current period

    private var current: PeriodShots {
        get { game.periods[game.currentIndex] }
        set { game.periods[game.currentIndex] = newValue }
    }

    // MARK: - Persistence (single JSON file in Documents)

    private static var shotsURL: URL {
        FileStore.documents.appendingPathComponent("shots.json")
    }

    private static func load() -> ShotGame? {
        guard let data = try? Data(contentsOf: shotsURL) else { return nil }
        return try? JSONDecoder().decode(ShotGame.self, from: data)
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(game)
            try data.write(to: Self.shotsURL, options: .atomic)
        } catch {
            print("ShotStore save failed: \(error)")
        }
    }
}

/// Shots for a single period.
struct PeriodShots: Codable {
    var home = 0
    var away = 0
}

/// The whole tally: one entry per period played (index 0 = Period 1). Only the period at
/// `currentIndex` is edited; earlier ones are locked once the period is advanced.
struct ShotGame: Codable {
    var periods: [PeriodShots] = [PeriodShots()]
    var currentIndex = 0
    /// Which end the home goalie defends in period 1. Default `true` (home team attacks
    /// to the right); a tap on the centre faceoff dot overrides it. Goalies swap ends
    /// each period, so this only sets the starting orientation.
    var homeStartsLeft = true

    init() {}

    /// Decode leniently so a game saved by an earlier version (without `homeStartsLeft`)
    /// still loads instead of being discarded.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        periods = try c.decodeIfPresent([PeriodShots].self, forKey: .periods) ?? [PeriodShots()]
        currentIndex = try c.decodeIfPresent(Int.self, forKey: .currentIndex) ?? 0
        homeStartsLeft = try c.decodeIfPresent(Bool.self, forKey: .homeStartsLeft) ?? true
    }
}
