import Foundation
import Observation

/// Shots-on-goal tally for the current game. Every shot is stored individually with its
/// rink position, the period it was taken in, and which team it credited, so the same data
/// drives both the Skott counter and the Skottkarta (shot map) tab. Per-team/period counts
/// are derived from this one list — no separate counters to keep in sync. `@Observable`
/// (iOS 17+) so the views bind to it, and it persists to a single JSON file in Documents
/// like `ConfigStore`.
@Observable
final class ShotStore {
    var game: ShotGame

    /// Standard hockey: three periods plus overtime. `currentIndex` can reach 3 (OT).
    static let maxPeriods = 4

    init() {
        self.game = Self.load() ?? ShotGame()
    }

    // MARK: - Mutations (each persists)

    /// Register a shot at a normalized rink position (0…1 on each axis). `isHome` is the
    /// attacking team the tap credited; `x`/`y` are stored raw so the map can mirror ends.
    func addShot(isHome: Bool, x: Double, y: Double) {
        game.shots.append(Shot(x: x, y: y, period: game.currentIndex, isHome: isHome))
        save()
    }

    /// Correct a mis-tap by dropping the most recent shot for that team in the current
    /// (editable) period. No-op if there is none.
    func removeHome() { removeLastShot(isHome: true) }
    func removeAway() { removeLastShot(isHome: false) }

    private func removeLastShot(isHome: Bool) {
        if let i = game.shots.lastIndex(where: { $0.period == game.currentIndex && $0.isHome == isHome }) {
            game.shots.remove(at: i)
            save()
        }
    }

    /// Lock the current period and start the next one. No-op once at overtime. Shots keep
    /// accumulating — advancing only moves which period new taps are filed under.
    func nextPeriod() {
        guard canAdvancePeriod else { return }
        game.currentIndex += 1
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

    var homeTotal: Int { game.shots.lazy.filter { $0.isHome }.count }
    var awayTotal: Int { game.shots.lazy.filter { !$0.isHome }.count }

    /// Shots in the current (editable) period — the big number the taps drive.
    var currentHome: Int { periodTotals(game.currentIndex).home }
    var currentAway: Int { periodTotals(game.currentIndex).away }

    var canAdvancePeriod: Bool { game.currentIndex < Self.maxPeriods - 1 }

    /// Number of periods played so far (1-based), i.e. Period 1 through the current one.
    var playedPeriodCount: Int { game.currentIndex + 1 }

    /// Home/away shot counts for a single period index.
    func periodTotals(_ index: Int) -> (home: Int, away: Int) {
        var home = 0, away = 0
        for shot in game.shots where shot.period == index {
            if shot.isHome { home += 1 } else { away += 1 }
        }
        return (home, away)
    }

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
            let totals = periodTotals(i)
            return (i, Self.periodLabel(i), home ? totals.home : totals.away)
        }
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

/// A single shot: its normalized rink position, the period it was taken in, and which team
/// it credited. `x`/`y` are the raw tap position (0 = left/top edge, 1 = right/bottom);
/// the shot map mirrors ends per team using this raw value.
struct Shot: Codable {
    var x: Double
    var y: Double
    var period: Int
    var isHome: Bool
}

/// The whole tally: every shot of the game plus which period is currently editable. Shots
/// accumulate across periods (advancing just changes which period new shots are filed
/// under); "Ny match" clears them.
struct ShotGame: Codable {
    var shots: [Shot] = []
    var currentIndex = 0
    /// Which end the home goalie defends in period 1. Default `true` (home team attacks
    /// to the right); a tap on the centre faceoff dot overrides it. Goalies swap ends
    /// each period, so this only sets the starting orientation.
    var homeStartsLeft = true

    init() {}

    /// Decode leniently so a game saved by an earlier version (or with missing keys) still
    /// loads instead of being discarded.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        shots = try c.decodeIfPresent([Shot].self, forKey: .shots) ?? []
        currentIndex = try c.decodeIfPresent(Int.self, forKey: .currentIndex) ?? 0
        homeStartsLeft = try c.decodeIfPresent(Bool.self, forKey: .homeStartsLeft) ?? true
    }
}
