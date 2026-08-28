import SwiftUI

/// The game situations an official can trigger from the Control screen.
///
/// Java analogy: this is an `enum` like you'd write in Java, but in Swift an enum
/// can carry computed properties and conform to protocols directly, so each case
/// knows its own label, icon, colour and what it should do to the audio.
enum GameEvent: String, CaseIterable, Identifiable, Codable {
    case avblasning      // Whistle — game paused
    case tekning         // Face-off — play resumes
    case entre           // Teams enter the ice — own sound, then advances (like a goal)
    case icing           // Icing — a flavour of Avblåsning (own sound, then advances)
    case offside         // Off-side — a flavour of Avblåsning (own sound, then advances)
    case hemmamal        // Home goal
    case bortamal        // Away goal
    case hemmautvisning  // Home penalty
    case bortautvisning  // Away penalty
    case fulltalig       // Back to full strength (penalty expired)
    case timeout
    case paus            // Intermission
    case matchslut       // Game end

    var id: String { rawValue }

    /// Swedish label shown on the big button.
    var title: String {
        switch self {
        case .avblasning:     return "Avblåsning"
        case .tekning:        return "Tekning"
        case .entre:          return "Entré"
        case .icing:          return "Icing"
        case .offside:        return "Off-side"
        case .hemmamal:       return "Hemmamål"
        case .bortamal:       return "Bortamål"
        case .hemmautvisning: return "Hemmautvisning"
        case .bortautvisning: return "Bortautvisning"
        case .fulltalig:      return "Fulltalig"
        case .timeout:        return "Timeout"
        case .paus:           return "Paus"
        case .matchslut:      return "Matchslut"
        }
    }

    /// Shorter label for the compact grid buttons, where long words would otherwise
    /// wrap awkwardly. Falls back to the full `title` for names that already fit.
    /// Setup and the now-playing bar keep the full `title`.
    var shortTitle: String {
        switch self {
        case .hemmautvisning: return "Utv. hemma"
        case .bortautvisning: return "Utv. borta"
        default:              return title
        }
    }

    /// Short helper text shown under the title.
    var subtitle: String {
        switch self {
        case .avblasning:     return "Nästa låt i spellistan"
        case .tekning:        return "Stoppa musiken"
        case .entre:          return "Entrelåt sedan pauslista"
        case .icing:          return "Icing-ljud sedan spellista"
        case .offside:        return "Offside-ljud sedan spellista"
        case .hemmamal:       return ""
        case .bortamal:       return ""
        case .hemmautvisning: return ""
        case .bortautvisning: return ""
        case .fulltalig:      return ""
        case .timeout:        return ""
        case .paus:           return "Paus-spellista"
        case .matchslut:      return ""
        }
    }

    /// SF Symbol name for the button icon.
    var systemImage: String {
        switch self {
        // Icon reflects what happens in the game (opposite of the music): Avblåsning
        // stops play, Tekning resumes it.
        case .avblasning:     return "stop.fill"
        case .tekning:        return "play.fill"
        case .entre:          return "figure.hockey"
        case .icing:          return "arrow.uturn.left"
        case .offside:        return "flag.slash"
        case .hemmamal:       return "house.fill"
        case .bortamal:       return "airplane"
        case .hemmautvisning: return "exclamationmark.triangle.fill"
        case .bortautvisning: return "exclamationmark.triangle"
        case .fulltalig:      return "person.3.fill"
        case .timeout:        return "hand.raised.fill"
        case .paus:           return "cup.and.saucer.fill"
        case .matchslut:      return "flag.checkered"
        }
    }

    /// Colour tint for the button, so officials can find them fast under pressure.
    var tint: Color {
        switch self {
        // Colour reflects what happens in the game (opposite of the music): Avblåsning
        // stops play (red), Tekning resumes it (green).
        case .avblasning:     return .red
        case .tekning:        return Color(red: 0.0, green: 0.5, blue: 0.13) // traffic-light green
        case .entre:          return .blue
        case .icing:          return .cyan
        case .offside:        return .yellow
        case .hemmamal:       return .green
        case .bortamal:       return .orange
        case .hemmautvisning: return .purple
        case .bortautvisning: return .indigo
        case .fulltalig:      return .mint
        case .timeout:        return .teal
        case .paus:           return .brown
        case .matchslut:      return .pink
        }
    }

    /// What triggering this event should do to playback.
    var action: EventAction {
        switch self {
        case .avblasning:     return .advanceGamePlaylist
        case .tekning:        return .stopAll
        case .paus:           return .playIntermissionPlaylist
        case .timeout:        return .playLoopedTrack
        // Entré: play the entrance sound, then start the pause playlist.
        case .entre:          return .playConfiguredTrackThenPaus
        // Goals and penalties are flavours of Avblåsning: play their sound, then advance.
        case .icing, .offside, .hemmamal, .bortamal,
             .hemmautvisning, .bortautvisning:
            return .playConfiguredTrackThenAdvance
        case .fulltalig, .matchslut:
            return .playConfiguredTrack
        }
    }

    /// Events that the user binds to a single track in Setup (played once, or looped).
    static var configurableTrackEvents: [GameEvent] {
        allCases.filter { $0.action.bindsSingleTrack }
    }

    /// Whether this event is shown in the simplified (non-advanced) Match screen.
    /// The rest are only visible when the user turns on "Avancerad" in Setup.
    var isBasic: Bool {
        switch self {
        case .avblasning, .tekning, .hemmamal, .bortamal, .paus, .matchslut:
            return true
        default:
            return false
        }
    }

    /// Display layout for the Control screen, grouped into rows. Most rows are pairs;
    /// the penalty-related events (both utvisningar + fulltalig) share a row of three.
    static var controlRows: [[GameEvent]] {
        [[.avblasning, .tekning],
         [.icing, .offside],
         // Away on the left, home on the right: for 2 of 3 periods the home team
         // attacks to the right, so this matches the ice most of the time.
         [.bortamal, .hemmamal],
         [.bortautvisning, .hemmautvisning, .fulltalig],
         [.timeout, .paus, .matchslut],
         [.entre]]
    }

    /// Row layout for the Match screen. In advanced mode this is the full `controlRows`;
    /// otherwise only the basic events are kept, dropping any row left empty.
    static func controlRows(advanced: Bool) -> [[GameEvent]] {
        guard !advanced else { return controlRows }
        return controlRows.compactMap { row in
            let basics = row.filter(\.isBasic)
            return basics.isEmpty ? nil : basics
        }
    }
}

/// The playback behaviour attached to an event. Keeping this separate from the
/// event itself (rather than hard-coding logic in the button) is the same idea as
/// a Strategy in Java: the coordinator reads the action and executes it.
enum EventAction: Equatable {
    case advanceGamePlaylist        // Avblåsning: skip to next track and play
    case stopAll                    // Tekning: stop everything
    case playConfiguredTrack        // Goals / penalties / game end: play once
    case playConfiguredTrackThenAdvance // Icing / Off-side: play own sound, then act as Avblåsning
    case playConfiguredTrackThenPaus // Entré: play own sound, then start the pause playlist
    case playLoopedTrack            // Timeout: loop one track until stopped (by Tekning)
    case playIntermissionPlaylist   // Paus

    /// Whether the event binds to a single configurable track in Setup (played once
    /// or looped), as opposed to a playlist or a fixed behaviour.
    var bindsSingleTrack: Bool {
        switch self {
        case .playConfiguredTrack, .playConfiguredTrackThenAdvance,
             .playConfiguredTrackThenPaus, .playLoopedTrack:
            return true
        case .advanceGamePlaylist, .stopAll, .playIntermissionPlaylist:
            return false
        }
    }
}
