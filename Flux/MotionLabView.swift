import SwiftUI

struct MotionLabView: View {
    @EnvironmentObject private var store: StudioStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false
    @State private var flipped = false
    @State private var orbOffset = CGSize.zero

    private var animation: Animation? {
        reduceMotion ? nil : store.settings.motion.animation(duration: store.settings.duration, bounce: store.settings.bounce)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeading(eyebrow: "Touch. Tweak. Repeat.", title: "Motion lab")
                    Text("Give your taps a little personality. These effects play inside Flux.")
                        .font(.subheadline).foregroundStyle(FluxPalette.muted)
                    Picker("Motion style", selection: $store.settings.motion) {
                        ForEach(MotionPreset.allCases) { preset in Text(preset.title).tag(preset) }
                    }.pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Label("The open / close", systemImage: "rectangle.expand.vertical").font(.headline)
                            Spacer()
                            Text("01").font(.system(.caption, design: .monospaced)).foregroundStyle(FluxPalette.muted)
                        }
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: expanded ? 22 : 19)
                                .fill(store.settings.accent.color.gradient)
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Image(systemName: expanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                    if expanded { Spacer(); Text("Hello, you.").font(.headline) }
                                }
                                if expanded {
                                    Text("A little space to slow down.")
                                        .font(.system(size: 23, weight: .medium, design: .rounded))
                                    Spacer(minLength: 0)
                                    Text("Tap to fold it away").font(.caption)
                                }
                            }.padding(20).foregroundStyle(.black)
                        }
                        .frame(width: expanded ? nil : 64, height: expanded ? 200 : 64)
                        .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            store.tap()
                            withAnimation(animation) { expanded.toggle() }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(expanded ? "Close animated card" : "Open animated card")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction {
                            store.tap()
                            withAnimation(animation) { expanded.toggle() }
                        }
                    }.fluxPanel()

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Label("The other side", systemImage: "rectangle.on.rectangle.angled").font(.headline)
                            Spacer()
                            Text("02").font(.system(.caption, design: .monospaced)).foregroundStyle(FluxPalette.muted)
                        }
                        Button {
                            store.tap()
                            withAnimation(animation) { flipped.toggle() }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(flipped ? store.settings.accent.color.opacity(0.22) : Color.white.opacity(0.06))
                                VStack(spacing: 12) {
                                    Image(systemName: flipped ? "sparkles" : "moon.stars.fill")
                                        .font(.system(size: 36)).foregroundStyle(store.settings.accent.color)
                                    Text(flipped ? "A whole new perspective." : "There’s another side.")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                    Text("TAP TO FLIP").font(.system(size: 9, design: .monospaced)).tracking(2)
                                        .foregroundStyle(FluxPalette.muted)
                                }
                                .rotation3DEffect(.degrees(flipped && !reduceMotion ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                            }
                            .frame(height: 190)
                            .rotation3DEffect(.degrees(flipped && !reduceMotion ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.3)
                        }.buttonStyle(.plain).accessibilityLabel("Flip animated card")
                    }.fluxPanel()

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Catch the glow", systemImage: "circle.dotted").font(.headline)
                            Spacer()
                            Text("03").font(.system(.caption, design: .monospaced)).foregroundStyle(FluxPalette.muted)
                        }
                        GeometryReader { geometry in
                            ZStack {
                                Circle().stroke(.white.opacity(0.06), style: StrokeStyle(lineWidth: 1, dash: [3, 7]))
                                    .frame(width: 165, height: 165)
                                Circle().fill(store.settings.accent.color.opacity(0.18))
                                    .frame(width: 100, height: 100).blur(radius: 16)
                                    .offset(orbOffset)
                                Circle()
                                    .fill(RadialGradient(colors: [.white, store.settings.accent.color, store.settings.accent.color.opacity(0.3)],
                                                         center: .topLeading, startRadius: 1, endRadius: 70))
                                    .frame(width: 60, height: 60)
                                    .shadow(color: store.settings.accent.color.opacity(0.4), radius: 20)
                                    .offset(orbOffset)
                                    .gesture(DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let x = max(-geometry.size.width / 2 + 34, min(geometry.size.width / 2 - 34, value.translation.width))
                                            let y = max(-70, min(70, value.translation.height))
                                            orbOffset = CGSize(width: x, height: y)
                                        }
                                        .onEnded { _ in
                                            store.tap()
                                            withAnimation(animation) { orbOffset = .zero }
                                        })
                                    .accessibilityLabel("Glowing orb. Drag and release to test the spring.")
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityAction {
                                        store.tap()
                                        withAnimation(animation) { orbOffset = orbOffset == .zero ? CGSize(width: 60, height: -35) : .zero }
                                    }
                            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                        }.frame(height: 210)
                        Text("Drag it. Let go. Feel the spring.").font(.caption).foregroundStyle(FluxPalette.muted)
                    }.fluxPanel()

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Tune the feeling").font(.headline)
                        ValueSlider(title: "Duration", value: $store.settings.duration, range: 0.2...1.5, unit: "s")
                        ValueSlider(title: "Bounce", value: $store.settings.bounce, range: 0...0.65, unit: "")
                            .disabled(store.settings.motion == .smooth || store.settings.motion == .drift)
                        Toggle("Haptic feedback", isOn: $store.settings.haptics)
                        if reduceMotion {
                            Text("Reduce Motion is enabled in iOS. Effects use instant transitions.")
                                .font(.caption).foregroundStyle(FluxPalette.muted)
                        }
                    }.fluxPanel()
                }.padding(22)
            }.background(FluxPalette.background).toolbar(.hidden, for: .navigationBar)
        }
    }
}
