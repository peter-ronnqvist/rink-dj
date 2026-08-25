import Foundation

/// An instruction/tip for the arena announcer (speaker), shown in the Speaker tab above
/// the referee-signal reference. Each tip has a title, an instruction, and — for the
/// announcement situations — a phrasing template and one or more worked examples.
struct SpeakerTip: Identifiable {
    let id: String            // title, used as identity
    let title: String
    let body: String
    let format: String?       // phrasing template, e.g. "Vid [tid] ..."
    let examples: [String]

    init(_ title: String, body: String, format: String? = nil, examples: [String] = []) {
        self.id = title
        self.title = title
        self.body = body
        self.format = format
        self.examples = examples
    }
}

extension SpeakerTip {
    static let all: [SpeakerTip] = [
        SpeakerTip(
            "Före match",
            body: "Under uppvärmningen, ca 5 minuter innan nedsläpp: presentera matchen och "
                + "hälsa publik och lag välkomna. Presentera därefter laguppställningarna – "
                + "börja med bortalaget."
        ),
        SpeakerTip(
            "Vid utvisning",
            body: "Efter att domaren har visat överträdelsen annonserar du utvisningen.",
            format: "Vid [tid] i [period] perioden utvisas [lag] nummer [nr], "
                + "[antal] minuter för [orsak].",
            examples: [
                "Vid 7:13 i andra perioden utvisas Flemingsbergs nummer 7, 2 minuter för tripping."
            ]
        ),
        SpeakerTip(
            "Vid mål",
            body: "Vänta med att annonsera målet tills efter tekning. Domaren meddelar "
                + "målskytt och assist(er).",
            format: "Vid [tid] i [period] perioden [tar ledningen / kvitterar / reducerar] "
                + "[lag] med [ställning]. Målskytt nummer [nr] [namn]. "
                + "Assist nummer [a], nummer [b].",
            examples: [
                "Vid 12:37 i första perioden tar Flemingsberg ledningen med 1–0. "
                    + "Målskytt spelare nummer 20, Christoffer Dahling, oassisterad.",
                "Vid 9:45 i andra perioden kvitterar Täby till 1–1. Målskytt spelare "
                    + "nummer 2, Nils Ghandi. Assist spelare nummer 5, Ove Sundberg."
            ]
        ),
    ]
}
