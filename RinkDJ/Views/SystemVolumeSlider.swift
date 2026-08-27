import SwiftUI
import MediaPlayer

/// A system output-volume slider, so the operator can duck the music during announcements
/// (e.g. team presentations before the game) without reaching for the hardware buttons.
///
/// Wraps `MPVolumeView` — Apple's only sanctioned in-app volume control, and the only way
/// to affect **Spotify's** volume, since the App Remote SDK exposes no volume API. It drives
/// the device's output volume, so it ducks Spotify and local audio together. The slider is
/// inert in the Simulator (no audio route); it works on a real device.
struct SystemVolumeSlider: UIViewRepresentable {
    var tint: Color

    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.showsRouteButton = false
        view.setVolumeThumbImage(nil, for: .normal) // use the default system thumb
        view.tintColor = UIColor(tint)
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        uiView.tintColor = UIColor(tint)
    }
}
