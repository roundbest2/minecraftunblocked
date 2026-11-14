import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: StudioStore
    @State private var confirmReset = false
    @State private var showGuide = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeading(eyebrow: "Keep it personal", title: "The details")
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Appearance").font(.headline)
                        AccentPicker()
                        Toggle("Animate wallpaper previews", isOn: $store.settings.animatePreviews)
                        Toggle("60 fps previews", isOn: $store.settings.highFrameRate)
                        Text("30 fps uses less power. Previews pause in Low Power Mode, with Reduce Motion, and when Flux is inactive. Video exports use 30 fps.")
                            .font(.caption).foregroundStyle(FluxPalette.muted)
                    }.fluxPanel()
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Touch").font(.headline)
                        Toggle("Haptic feedback", isOn: $store.settings.haptics)
                        Button("Try a soft tap") { store.tap() }
                    }.fluxPanel()
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Your device stays yours", systemImage: "hand.raised").font(.headline)
                        Text("Flux creates wallpapers and customizes its own interface. It does not jailbreak iOS, replace system animations, or modify other apps.")
                        Text("Your settings stay on your device. No account, ads, tracking, or server. Photos access is requested only when you save a Live Photo, and is add-only.")
                    }.font(.subheadline).foregroundStyle(FluxPalette.muted).fluxPanel()
                    Button { showGuide = true } label: {
                        HStack { Label("Wallpaper setup guide", systemImage: "book"); Spacer(); Image(systemName: "chevron.right") }
                            .font(.subheadline).fluxPanel()
                    }.buttonStyle(.plain)
                    Button("Reset preferences", role: .destructive) { confirmReset = true }
                        .font(.subheadline).frame(maxWidth: .infinity).padding()
                    VStack(spacing: 7) {
                        Text("FLUX").font(.system(size: 22, weight: .black, design: .rounded)).tracking(6)
                        Text("MOTION STUDIO • 1.0").font(.system(size: 9, design: .monospaced)).tracking(2)
                    }.foregroundStyle(FluxPalette.muted).frame(maxWidth: .infinity).padding(.vertical, 16)
                }.padding(22)
            }.background(FluxPalette.background).toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $showGuide) { WallpaperGuide() }
                .confirmationDialog("Reset all Flux preferences?", isPresented: $confirmReset, titleVisibility: .visible) {
                    Button("Reset preferences", role: .destructive) { store.reset() }
                } message: { Text("Saved photos and videos are kept. Your chosen style, favorites, colors, and motion settings will reset.") }
        }
    }
}
