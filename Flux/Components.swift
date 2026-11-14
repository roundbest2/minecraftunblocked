import SwiftUI

enum FluxPalette {
    static let background = Color(red: 0.035, green: 0.04, blue: 0.055)
    static let panel = Color(red: 0.075, green: 0.08, blue: 0.10)
    static let muted = Color(red: 0.60, green: 0.62, blue: 0.68)
}

extension View {
    func fluxPanel() -> some View {
        self.padding(18)
            .background(FluxPalette.panel, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.06)))
    }
}

struct PageHeading: View {
    let eyebrow: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(3).foregroundStyle(FluxPalette.muted)
            Text(title).font(.system(size: 36, weight: .semibold, design: .rounded))
                .tracking(-1.4).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AccentPicker: View {
    @EnvironmentObject private var store: StudioStore
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Accent.allCases) { accent in
                Button {
                    store.settings.accent = accent
                    store.tap()
                } label: {
                    Circle().fill(accent.color)
                        .frame(width: 34, height: 34)
                        .overlay {
                            if store.settings.accent == accent {
                                Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.black)
                            }
                        }
                        .padding(5)
                        .overlay(Circle().strokeBorder(store.settings.accent == accent ? accent.color : .clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accent.title + " accent")
                .accessibilityAddTraits(store.settings.accent == accent ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }
}

struct ValueSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text(String(format: "%.2f", value) + unit)
                    .font(.system(.caption, design: .monospaced)).foregroundStyle(FluxPalette.muted)
            }
            Slider(value: $value, in: range).accessibilityLabel(title)
        }
    }
}

struct LockOverlay: View {
    var compact = false
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: "lock.fill")
                .font(.system(size: compact ? 12 : 17)).padding(.top, compact ? 28 : 40)
            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.system(size: compact ? 12 : 14, weight: .medium))
                .padding(.top, 14)
            Text(Date.now, format: .dateTime.hour().minute())
                .font(.system(size: compact ? 56 : 76, weight: .thin, design: .rounded))
                .tracking(-3).minimumScaleFactor(0.6).lineLimit(1)
            Spacer()
            HStack {
                Image(systemName: "flashlight.off.fill")
                Spacer()
                Image(systemName: "camera.fill")
            }
            .font(.system(size: compact ? 13 : 17))
            .padding(.horizontal, 28).padding(.bottom, 24)
            Capsule().fill(.white.opacity(0.8)).frame(width: compact ? 75 : 105, height: 4)
                .padding(.bottom, 10)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .accessibilityHidden(true)
    }
}

struct PrimaryButton: View {
    let title: String
    let symbol: String
    var action: () -> Void
    @EnvironmentObject private var store: StudioStore
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .foregroundStyle(.black)
                .background(store.settings.accent.color, in: Capsule())
        }.buttonStyle(.plain)
    }
}

struct HomeOverlay: View {
    private let symbols = ["message.fill", "music.note", "camera.fill", "map.fill", "calendar", "sun.max.fill", "heart.fill", "gearshape.fill"]
    var body: some View {
        VStack(spacing: 26) {
            Text("HOME PREVIEW").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2).padding(.top, 44)
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "sun.max.fill").font(.title2)
                    Text("Stay curious.").font(.headline)
                    Text("Make space for something new.").font(.caption)
                }
                Spacer()
            }.padding(20).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 22) {
                ForEach(symbols, id: \.self) { symbol in
                    Image(systemName: symbol).font(.system(size: 21))
                        .frame(width: 46, height: 46)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            Spacer()
            Text("A theme preview inside Flux")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.8)).padding(.bottom, 18)
        }.padding(.horizontal, 20).foregroundStyle(.white).accessibilityHidden(true)
    }
}
