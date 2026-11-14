import SwiftUI
import Combine
import UIKit

enum WallpaperStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case aurora, liquid, orbit, prism, grid, stardust
    var id: String { rawValue }
    var title: String {
        switch self {
        case .aurora: return "Aurora"
        case .liquid: return "Liquid"
        case .orbit: return "Orbit"
        case .prism: return "Prism"
        case .grid: return "Afterhours"
        case .stardust: return "Stardust"
        }
    }
    var subtitle: String {
        switch self {
        case .aurora: return "Light that drifts."
        case .liquid: return "Soft shapes. Endless flow."
        case .orbit: return "A little out of this world."
        case .prism: return "Color, with a new angle."
        case .grid: return "Meet me in the future."
        case .stardust: return "Your own tiny universe."
        }
    }
    var symbol: String {
        switch self {
        case .aurora: return "waveform.path"
        case .liquid: return "drop.fill"
        case .orbit: return "circle.hexagongrid"
        case .prism: return "triangle.fill"
        case .grid: return "square.grid.3x3"
        case .stardust: return "sparkles"
        }
    }
}

enum Accent: String, CaseIterable, Codable, Identifiable, Sendable {
    case violet, mint, coral, ice
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var rgb: (Double, Double, Double) {
        switch self {
        case .violet: return (0.69, 0.56, 1)
        case .mint: return (0.69, 1, 0.47)
        case .coral: return (1, 0.47, 0.52)
        case .ice: return (0.4, 0.85, 1)
        }
    }
    var color: Color { Color(red: rgb.0, green: rgb.1, blue: rgb.2) }
}

enum MotionPreset: String, CaseIterable, Codable, Identifiable, Sendable {
    case smooth, spring, snap, drift
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    func animation(duration: Double, bounce: Double) -> Animation {
        switch self {
        case .smooth: return .easeInOut(duration: duration)
        case .spring: return .spring(duration: duration, bounce: bounce)
        case .snap: return .snappy(duration: duration * 0.7, extraBounce: bounce * 0.2)
        case .drift: return .easeInOut(duration: duration * 1.7)
        }
    }
}

struct StudioSettings: Codable, Equatable, Sendable {
    var wallpaper: WallpaperStyle = .aurora
    var accent: Accent = .violet
    var motion: MotionPreset = .spring
    var speed: Double = 1
    var intensity: Double = 0.8
    var duration: Double = 0.65
    var bounce: Double = 0.3
    var haptics: Bool = true
    var animatePreviews: Bool = true
    var highFrameRate: Bool = false
    var favorites: Set<WallpaperStyle> = [.aurora, .liquid]

    func validated() -> StudioSettings {
        var result = self
        result.speed = speed.isFinite ? min(2, max(0.5, speed)) : 1
        result.intensity = intensity.isFinite ? min(1, max(0.2, intensity)) : 0.8
        result.duration = duration.isFinite ? min(1.5, max(0.2, duration)) : 0.65
        result.bounce = bounce.isFinite ? min(0.65, max(0, bounce)) : 0.3
        return result
    }
}

@MainActor
final class StudioStore: ObservableObject {
    @Published var settings: StudioSettings {
        didSet { save() }
    }
    private let defaults: UserDefaults
    private let key = "flux.studio.settings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let value = try? JSONDecoder().decode(StudioSettings.self, from: data) {
            settings = value.validated()
        } else {
            settings = StudioSettings()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings.validated()) {
            defaults.set(data, forKey: key)
        }
    }

    func favorite(_ style: WallpaperStyle) {
        if settings.favorites.contains(style) {
            settings.favorites.remove(style)
        } else {
            settings.favorites.insert(style)
        }
        tap()
    }

    func tap() {
        guard settings.haptics else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func reset() { settings = StudioSettings() }
}
