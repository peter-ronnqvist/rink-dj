import SwiftUI

/// The app's branded backdrop: a dark charcoal-to-black gradient with a soft glow of
/// the team's accent colour behind the header. Replaces the flat system background so
/// the colourful event buttons and the club logo stand out. On-brand for Flemingsbergs
/// IK (black + yellow), and it adapts to any club because the glow uses their accent.
struct BrandBackground: View {
    var accent: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.13), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            // Soft halo of the club colour at the top, behind the logo/header.
            RadialGradient(
                colors: [accent.opacity(0.22), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 340
            )
        }
        .ignoresSafeArea()
    }
}
