import SwiftUI

/// Team look-and-feel shown in the app header. Ships with Flemingsbergs IK as the
/// default, but any club can change the name, logo and accent colour in Setup — the
/// app is not locked to one team.
struct TeamBranding: Codable, Hashable {
    var teamName: String

    /// Name of a logo image bundled in the asset catalog (e.g. the default "TeamLogo").
    var logoAssetName: String?

    /// File name of a user-imported logo stored in Documents/Branding. Takes
    /// precedence over `logoAssetName` when present.
    var logoFileName: String?

    /// Accent colour stored as a "#RRGGBB" hex string so it round-trips through JSON.
    var accentColorHex: String

    static let flemingsbergsIK = TeamBranding(
        teamName: "Flemingsbergs IK",
        logoAssetName: "TeamLogo",
        logoFileName: nil,
        accentColorHex: "#FFDD00" // FIK yellow (from flemingsbergsik.se)
    )

    var accentColor: Color { Color(hex: accentColorHex) ?? .green }
}

extension Color {
    /// Build a Color from a "#RRGGBB" (or "RRGGBB") hex string. Returns nil if malformed.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt64(s, radix: 16) else { return nil }
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
