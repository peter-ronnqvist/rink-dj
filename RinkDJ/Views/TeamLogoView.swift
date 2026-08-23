import SwiftUI
import UIKit

/// Shows the current team's logo: a user-imported image if set, otherwise the
/// bundled asset, otherwise a neutral SF Symbol placeholder. Keeping this in one
/// place means both the Control header and Setup show branding consistently.
struct TeamLogoView: View {
    let branding: TeamBranding
    var size: CGFloat = 44

    var body: some View {
        logoImage
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private var logoImage: some View {
        if let fileName = branding.logoFileName,
           let url = FileStore.brandingLogoURL(fileName: fileName),
           let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else if let asset = branding.logoAssetName, UIImage(named: asset) != nil {
            Image(asset)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "sportscourt.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(branding.accentColor)
        }
    }
}
