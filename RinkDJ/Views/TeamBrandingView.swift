import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

/// Configure the team name, logo and accent colour. Defaults to Flemingsbergs IK but
/// any club can set their own — the app is not locked to one team.
struct TeamBrandingView: View {
    @Environment(ConfigStore.self) private var store
    @State private var showLogoImporter = false
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        @Bindable var store = store

        Form {
            Section("Förhandsvisning") {
                HStack(spacing: 14) {
                    TeamLogoView(branding: store.config.branding, size: 60)
                    Text(store.config.branding.teamName)
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
            }

            Section("Lagnamn") {
                TextField("Lagnamn", text: $store.config.branding.teamName)
                    .onChange(of: store.config.branding.teamName) { store.save() }
            }

            Section("Färg") {
                ColorPicker("Accentfärg",
                            selection: Binding(
                                get: { store.config.branding.accentColor },
                                set: { newColor in
                                    store.config.branding.accentColorHex = newColor.toHex()
                                    store.save()
                                }))
            }

            Section {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Välj från Bilder…", systemImage: "photo.on.rectangle")
                }
                Button {
                    showLogoImporter = true
                } label: {
                    Label("Välj från Filer…", systemImage: "folder")
                }
                if store.config.branding.logoFileName != nil {
                    Button("Använd standardlogotyp", role: .destructive) {
                        store.config.branding.logoFileName = nil
                        store.save()
                    }
                }
            } header: {
                Text("Logotyp")
            } footer: {
                Text("Standard är Flemingsbergs IK. Välj en egen (PNG med transparens rekommenderas) för ett annat lag.")
            }
        }
        .navigationTitle("Lag")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showLogoImporter,
                      allowedContentTypes: [.image],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                store.importLogo(from: url)
            }
        }
        .onChange(of: photoItem) {
            guard let photoItem else { return }
            Task {
                if let data = try? await photoItem.loadTransferable(type: Data.self) {
                    store.importLogo(data: data)
                }
                self.photoItem = nil
            }
        }
    }
}

extension Color {
    /// Convert to a "#RRGGBB" hex string for persistence.
    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int((r * 255).rounded())
        let gi = Int((g * 255).rounded())
        let bi = Int((b * 255).rounded())
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
