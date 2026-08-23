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
        case .hemmamal, .bortamal, .hemmautvisning,
             .bortautvisning, .timeout, .matchslut:
            return .playConfiguredTrack
        }
    }

    /// Events that the user binds to a single track in Setup.
    static var configurableTrackEvents: [GameEvent] {
        allCases.filter { $0.action == .playConfiguredTrack }
    }

    /// Display order on the Control screen (roughly by how often they're used).
    static var controlOrder: [GameEvent] {
        [.avblasning, .tekning,
         .hemmamal, .bortamal,
         .hemmautvisning, .bortautvisning,
         .timeout, .paus, .matchslut]
    }
}

/// The playback behaviour attached to an event. Keeping this separate from the
/// event itself (rather than hard-coding logic in the button) is the same idea as
/// a Strategy in Java: the coordinator reads the action and executes it.
enum EventAction: Equatable {
    case advanceGamePlaylist        // Avblåsning: skip to next track and play
    case stopAll                    // Tekning: stop everything
    case playConfiguredTrack        // Goals / penalties / timeout / game end
    case playIntermissionPlaylist   // Paus
}
