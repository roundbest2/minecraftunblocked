import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: StudioStore
    var body: some View {
        TabView {
            StudioView()
                .tabItem { Label("Studio", systemImage: "slider.horizontal.3") }
            WallpaperGallery()
                .tabItem { Label("Wallpapers", systemImage: "rectangle.portrait.on.rectangle.portrait") }
            MotionLabView()
                .tabItem { Label("Motion", systemImage: "wand.and.stars") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .toolbarBackground(FluxPalette.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

struct StudioView: View {
    @EnvironmentObject private var store: StudioStore
    @State private var showEditor = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        HStack(spacing: 7) {
                            Image(systemName: "waveform.path").foregroundStyle(store.settings.accent.color)
                            Text("FLUX").font(.system(size: 19, weight: .black, design: .rounded)).tracking(4)
                        }
                        Spacer()
                        Text("MAKE IT YOURS").font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(1.4).foregroundStyle(FluxPalette.muted)
                    }.padding(.top, 12)
                    PageHeading(eyebrow: "Your personal motion studio", title: "Make your\nscreen move.")
                    Button { showEditor = true } label: {
                        ZStack(alignment: .bottomLeading) {
                            WallpaperSurface(settings: store.settings, animated: !showEditor).frame(height: 360)
                            VStack(alignment: .leading, spacing: 8) {
                                Label("LIVE CANVAS", systemImage: "smallcircle.filled.circle")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2)
                                    .padding(.horizontal, 10).padding(.vertical, 7)
                                    .background(.ultraThinMaterial, in: Capsule())
                                Spacer()
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(store.settings.wallpaper.title).font(.system(size: 32, weight: .medium, design: .rounded))
                                        Text(store.settings.wallpaper.subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right").font(.title3)
                                        .frame(width: 48, height: 48).background(.white.opacity(0.15), in: Circle())
                                }
                            }.padding(24)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.12)))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Customize " + store.settings.wallpaper.title + " wallpaper")

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Set the mood").font(.headline)
                            Spacer()
                            Text("06 STYLES").font(.system(size: 10, design: .monospaced)).foregroundStyle(FluxPalette.muted)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 9) {
                                ForEach(WallpaperStyle.allCases) { style in
                                    Button {
                                        store.settings.wallpaper = style
                                        store.tap()
                                    } label: {
                                        Label(style.title, systemImage: style.symbol)
                                            .font(.system(size: 12, weight: .medium))
                                            .padding(.horizontal, 15).padding(.vertical, 12)
                                            .background(store.settings.wallpaper == style ? store.settings.accent.color.opacity(0.18) : FluxPalette.panel, in: Capsule())
                                            .foregroundStyle(store.settings.wallpaper == style ? store.settings.accent.color : .white)
                                    }.buttonStyle(.plain)
                                        .accessibilityAddTraits(store.settings.wallpaper == style ? .isSelected : [])
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        Text("A color that feels like you").font(.headline)
                        AccentPicker()
                    }.fluxPanel()
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkle").foregroundStyle(store.settings.accent.color)
                        Text("Create a wallpaper. Play with motion. Find your atmosphere.")
                            .font(.subheadline).foregroundStyle(FluxPalette.muted)
                    }.padding(.bottom, 12)
                }.padding(.horizontal, 22)
            }
            .background(FluxPalette.background)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showEditor) { WallpaperEditor() }
        }
    }
}

struct WallpaperGallery: View {
    @EnvironmentObject private var store: StudioStore
    @State private var onlyFavorites = false
    @State private var showEditor = false
    private var styles: [WallpaperStyle] {
        WallpaperStyle.allCases.filter { !onlyFavorites || store.settings.favorites.contains($0) }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeading(eyebrow: "Small screen. Big atmosphere.", title: "Wallpapers")
                    Picker("Collection", selection: $onlyFavorites) {
                        Text("All styles").tag(false)
                        Text("Favorites").tag(true)
                    }.pickerStyle(.segmented)
                    if styles.isEmpty {
                        ContentUnavailableView("Your favorites live here", systemImage: "heart",
                                               description: Text("Tap a heart on any wallpaper to save it."))
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 22) {
                        ForEach(styles) { style in
                            VStack(alignment: .leading, spacing: 10) {
                                Button {
                                    store.settings.wallpaper = style
                                    store.tap()
                                    showEditor = true
                                } label: {
                                    WallpaperSurface(settings: configuration(style), animated: false)
                                        .frame(height: 225)
                                        .overlay(alignment: .topLeading) {
                                            Image(systemName: style.symbol).font(.caption)
                                                .padding(11).background(.ultraThinMaterial, in: Circle()).padding(12)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Open " + style.title)
                                HStack {
                                    Text(style.title).font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Button { store.favorite(style) } label: {
                                        Image(systemName: store.settings.favorites.contains(style) ? "heart.fill" : "heart")
                                            .foregroundStyle(store.settings.favorites.contains(style) ? store.settings.accent.color : FluxPalette.muted)
                                            .frame(width: 44, height: 44)
                                    }.buttonStyle(.plain)
                                        .accessibilityLabel((store.settings.favorites.contains(style) ? "Unfavorite " : "Favorite ") + style.title)
                                }
                            }
                        }
                    }
                }.padding(22)
            }.background(FluxPalette.background)
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $showEditor) { WallpaperEditor() }
        }
    }
    private func configuration(_ style: WallpaperStyle) -> StudioSettings {
        var settings = store.settings
        settings.wallpaper = style
        return settings
    }
}
