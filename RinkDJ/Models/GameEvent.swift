import SwiftUI

/// The game situations an official can trigger from the Control screen.
///
/// Java analogy: this is an `enum` like you'd write in Java, but in Swift an enum
/// can carry computed properties and conform to protocols directly, so each case
/// knows its own label, icon, colour and what it should do to the audio.
enum GameEvent: String, CaseIterable, Identifiable, Codable {
    case avblasning      // Whistle — game paused
    case tekning         // Face-off — play resumes
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

    /// Short helper text shown under the title.
    var subtitle: String {
        switch self {
        case .avblasning:     return "Nästa låt i spellistan"
        case .tekning:        return "Stoppa musiken"
        case .hemmamal:       return "Hemmalagets mål"
        case .bortamal:       return "Bortalagets mål"
        case .hemmautvisning: return "Utvisning hemma"
        case .bortautvisning: return "Utvisning borta"
        case .fulltalig:      return "Åter full styrka"
        case .timeout:        return "Timeout-låt"
        case .paus:           return "Paus-spellista"
        case .matchslut:      return "Matchslut-låt"
        }
    }

    /// SF Symbol name for the button icon.
    var systemImage: String {
        switch self {
        case .avblasning:     return "forward.fill"
        case .tekning:        return "stop.fill"
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
        case .avblasning:     return .blue
        case .tekning:        return .red
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
        case .hemmamal, .bortamal, .hemmautvisning,
             .bortautvisning, .fulltalig, .matchslut:
            return .playConfiguredTrack
        }
    }

    /// Events that the user binds to a single track in Setup (played once, or looped).
    static var configurableTrackEvents: [GameEvent] {
        allCases.filter { $0.action.bindsSingleTrack }
    }

    /// Display layout for the Control screen, grouped into rows. Most rows are pairs;
    /// the penalty-related events (both utvisningar + fulltalig) share a row of three.
    static var controlRows: [[GameEvent]] {
        [[.avblasning, .tekning],
         [.hemmamal, .bortamal],
         [.hemmautvisning, .bortautvisning, .fulltalig],
         [.timeout, .paus, .matchslut]]
    }
}

/// The playback behaviour attached to an event. Keeping this separate from the
/// event itself (rather than hard-coding logic in the button) is the same idea as
/// a Strategy in Java: the coordinator reads the action and executes it.
enum EventAction: Equatable {
    case advanceGamePlaylist        // Avblåsning: skip to next track and play
    case stopAll                    // Tekning: stop everything
    case playConfiguredTrack        // Goals / penalties / game end: play once
    case playLoopedTrack            // Timeout: loop one track until stopped (by Tekning)
    case playIntermissionPlaylist   // Paus

    /// Whether the event binds to a single configurable track in Setup (played once
    /// or looped), as opposed to a playlist or a fixed behaviour.
    var bindsSingleTrack: Bool {
        switch self {
        case .playConfiguredTrack, .playLoopedTrack:
            return true
        case .advanceGamePlaylist, .stopAll, .playIntermissionPlaylist:
            return false
        }
    }
}
