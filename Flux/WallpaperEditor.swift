import SwiftUI

struct WallpaperEditor: View {
    @EnvironmentObject private var store: StudioStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var export = ExportController()
    @State private var homePreview = false
    @State private var showGuide = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("Preview", selection: $homePreview) {
                        Text("Lock Screen").tag(false)
                        Text("Home Screen").tag(true)
                    }.pickerStyle(.segmented)
                    ZStack {
                        WallpaperSurface(settings: store.settings)
                        if homePreview { HomeOverlay() } else { LockOverlay() }
                    }
                    .frame(width: 248, height: 505)
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .overlay(RoundedRectangle(cornerRadius: 36).strokeBorder(.white.opacity(0.2), lineWidth: 3))
                    .shadow(color: store.settings.accent.color.opacity(0.15), radius: 30)
                    .accessibilityLabel(store.settings.wallpaper.title + " wallpaper preview")

                    VStack(alignment: .leading, spacing: 20) {
                        AccentPicker()
                        ValueSlider(title: "Motion speed", value: $store.settings.speed, range: 0.5...2, unit: "×")
                        ValueSlider(title: "Intensity", value: $store.settings.intensity, range: 0.2...1, unit: "")
                    }.fluxPanel().disabled(export.isBusy)

                    VStack(spacing: 12) {
                        if export.isBusy {
                            VStack(spacing: 12) {
                                ProgressView(value: export.progress)
                                Text(export.status).font(.caption).foregroundStyle(FluxPalette.muted)
                                Button("Cancel export", role: .cancel) { export.cancel() }
                                    .font(.subheadline)
                            }.fluxPanel()
                        } else {
                            PrimaryButton(title: "Save Live Photo", symbol: "livephoto") {
                                export.start(.livePhoto, settings: store.settings)
                            }
                            HStack(spacing: 12) {
                                exportButton("Share still", icon: "photo", kind: .still)
                                exportButton("Share loop", icon: "play.rectangle", kind: .movie)
                            }
                        }
                        Text("Live Photos can animate on the Lock Screen when iOS supports the image. Home Screen wallpapers stay still.")
                            .font(.caption).foregroundStyle(FluxPalette.muted)
                            .multilineTextAlignment(.center).padding(.horizontal, 6)
                        Button("How to use your wallpaper") { showGuide = true }.font(.subheadline)
                    }
                }.padding(22)
            }
            .background(FluxPalette.background)
            .navigationTitle(store.settings.wallpaper.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.disabled(export.isBusy)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { store.favorite(store.settings.wallpaper) } label: {
                        Image(systemName: store.settings.favorites.contains(store.settings.wallpaper) ? "heart.fill" : "heart")
                    }.accessibilityLabel("Toggle favorite")
                }
            }
            .interactiveDismissDisabled(export.isBusy)
            .sheet(item: $export.shareItem, onDismiss: { export.cleanSharedFiles() }) { item in
                ActivitySheet(urls: item.files)
            }
            .sheet(isPresented: $showGuide) { WallpaperGuide() }
            .alert("Export", isPresented: Binding(
                get: { export.message != nil },
                set: { if !$0 { export.message = nil } }
            )) {
                Button("OK", role: .cancel) { export.message = nil }
            } message: { Text(export.message ?? "") }
        }
    }

    private func exportButton(_ title: String, icon: String, kind: ExportKind) -> some View {
        Button { export.start(kind, settings: store.settings) } label: {
            Label(title, systemImage: icon).font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(FluxPalette.panel, in: Capsule())
        }.buttonStyle(.plain)
    }
}

struct WallpaperGuide: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeading(eyebrow: "A new look, in a few taps", title: "Take it outside.")
                    guideStep("01", title: "Save your creation", text: "Choose Save Live Photo in Flux and allow access to add photos. Flux does not need to read your photo library.")
                    guideStep("02", title: "Open Wallpaper settings", text: "Go to Settings → Wallpaper → Add New Wallpaper → Photos → Live Photo, then select the saved image.")
                    guideStep("03", title: "Turn motion on", text: "If iOS offers the Live Photo play button, turn it on and tap Add. The animation plays when your phone wakes; it does not loop continuously.")
                    guideStep("04", title: "Make a pair", text: "Use the still version for your Home Screen. Flux's custom interface animations and theme previews stay inside Flux.")
                    Text("Some generated Live Photos are not eligible for Lock Screen motion. If iOS says motion is unavailable, you can still use the image as a still wallpaper or share its video loop.")
                        .font(.subheadline).foregroundStyle(FluxPalette.muted).fluxPanel()
                    Link("Apple’s Live Photo wallpaper guide", destination: URL(string: "https://support.apple.com/120734")!)
                        .font(.subheadline)
                }.padding(22)
            }.background(FluxPalette.background)
                .navigationTitle("Wallpaper guide").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
    private func guideStep(_ number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number).font(.system(.caption, design: .monospaced)).foregroundStyle(FluxPalette.muted)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(FluxPalette.muted)
            }
        }
    }
}
