import Foundation

/// A referee hand signal (domartecken), shown in the Speaker tab as a reference so the
/// arena announcer can recognise a call and announce it correctly.
///
/// Data is transcribed verbatim from the source PDF (rule 29.x). `imageNames` holds one
/// image for a static signal, or two for a two-part motion — the detail view cross-fades
/// between the two frames as a light "animation".
struct RefereeSignal: Identifiable {
    /// The three groups the PDF organises signals into.
    enum Category: String, CaseIterable, Identifiable {
        case utvisningar = "Utvisningar"
        case ovriga = "Övriga tecken"
        case linjedomare = "Linjedomartecken"
        var id: String { rawValue }
    }

    let number: String        // e.g. "29.1"
    let name: String          // caption as printed in the PDF
    let category: Category
    let imageNames: [String]  // 1 = static, 2 = cross-fade

    var id: String { number }

    /// True when this signal has a two-part motion to animate.
    var isAnimated: Bool { imageNames.count > 1 }

    /// Signals for a category, in rule order.
    static func signals(in category: Category) -> [RefereeSignal] {
        all.filter { $0.category == category }
    }
}

extension RefereeSignal {
    static let all: [RefereeSignal] = [
        // MARK: Huvuddomares tecken – utvisningar
        .init(number: "29.1",  name: "Boarding",                 category: .utvisningar, imageNames: ["sign_29_01"]),
        .init(number: "29.2",  name: "Butt-Ending",              category: .utvisningar, imageNames: ["sign_29_02"]),
        .init(number: "29.3",  name: "Charging",                 category: .utvisningar, imageNames: ["sign_29_03"]),
        .init(number: "29.4",  name: "Checking from Behind",     category: .utvisningar, imageNames: ["sign_29_04"]),
        .init(number: "29.5",  name: "Checking to the head",     category: .utvisningar, imageNames: ["sign_29_05"]),
        .init(number: "29.6",  name: "Clipping",                 category: .utvisningar, imageNames: ["sign_29_06"]),
        .init(number: "29.7",  name: "Crosschecking",            category: .utvisningar, imageNames: ["sign_29_07"]),
        .init(number: "29.8",  name: "Delay of game – puck out", category: .utvisningar, imageNames: ["sign_29_08a", "sign_29_08b"]),
        .init(number: "29.9",  name: "Avvaktande utvisning",     category: .utvisningar, imageNames: ["sign_29_09"]),
        .init(number: "29.10", name: "Elbowing",                 category: .utvisningar, imageNames: ["sign_29_10"]),
        .init(number: "29.11", name: "Illegal handling the puck",category: .utvisningar, imageNames: ["sign_29_11"]),
        .init(number: "29.12", name: "High-sticking",            category: .utvisningar, imageNames: ["sign_29_12"]),
        .init(number: "29.13", name: "Holding",                  category: .utvisningar, imageNames: ["sign_29_13"]),
        .init(number: "29.14", name: "Holding the stick",        category: .utvisningar, imageNames: ["sign_29_14a", "sign_29_14b"]),
        .init(number: "29.15", name: "Hooking",                  category: .utvisningar, imageNames: ["sign_29_15a", "sign_29_15b"]),
        .init(number: "29.16", name: "Interference",             category: .utvisningar, imageNames: ["sign_29_16"]),
        .init(number: "29.17", name: "Illegal Hit",              category: .utvisningar, imageNames: ["sign_29_17"]),
        .init(number: "29.18", name: "Kneeing",                  category: .utvisningar, imageNames: ["sign_29_18"]),
        .init(number: "29.19", name: "Late hit",                 category: .utvisningar, imageNames: ["sign_29_19"]),
        .init(number: "29.20", name: "Abuse of officials / Unsportsmanlike Conduct", category: .utvisningar, imageNames: ["sign_29_20"]),
        .init(number: "29.21", name: "Roughing/Fighting",        category: .utvisningar, imageNames: ["sign_29_21"]),
        .init(number: "29.22", name: "Spearing",                 category: .utvisningar, imageNames: ["sign_29_22"]),
        .init(number: "29.23", name: "Slashing",                 category: .utvisningar, imageNames: ["sign_29_23"]),
        .init(number: "29.24", name: "Straffslag",               category: .utvisningar, imageNames: ["sign_29_24"]),
        .init(number: "29.25", name: "Tripping",                 category: .utvisningar, imageNames: ["sign_29_25"]),

        // MARK: Huvuddomares tecken – övriga tecken
        .init(number: "29.26", name: "Mål",                      category: .ovriga, imageNames: ["sign_29_26"]),
        .init(number: "29.27", name: "Spelarbyte",              category: .ovriga, imageNames: ["sign_29_27"]),
        .init(number: "29.28", name: "Spelare i målområdet",     category: .ovriga, imageNames: ["sign_29_28"]),
        .init(number: "29.29", name: "Time-out",                 category: .ovriga, imageNames: ["sign_29_29"]),
        .init(number: "29.30", name: "Videomålbedömning",        category: .ovriga, imageNames: ["sign_29_30"]),
        .init(number: "29.31", name: "Wash out",                 category: .ovriga, imageNames: ["sign_29_31"]),

        // MARK: Linjedomares tecken
        .init(number: "29.32", name: "Avvaktande icing / offside",category: .linjedomare, imageNames: ["sign_29_32"]),
        .init(number: "29.33", name: "Icing (främre linjeman)",   category: .linjedomare, imageNames: ["sign_29_33"]),
        .init(number: "29.34", name: "Icing (bakre linjeman)",    category: .linjedomare, imageNames: ["sign_29_34"]),
        .init(number: "29.35", name: "Too many players",          category: .linjedomare, imageNames: ["sign_29_35"]),
        .init(number: "29.36", name: "Offside",                   category: .linjedomare, imageNames: ["sign_29_36"]),
        .init(number: "29.37", name: "Wash out",                  category: .linjedomare, imageNames: ["sign_29_37"]),
    ]
}
