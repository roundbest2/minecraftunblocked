import CoreGraphics
import Foundation

/// One deterministic renderer is shared by the live canvas, photo, and movie export.
enum WallpaperRenderer {
    static let base = CGSize(width: 1000, height: 2166)

    static func draw(in context: CGContext, size: CGSize, time: Double, settings: StudioSettings) {
        guard size.width > 0, size.height > 0 else { return }
        context.saveGState()
        defer { context.restoreGState() }
        context.scaleBy(x: size.width / base.width, y: size.height / base.height)
        let bounds = CGRect(origin: .zero, size: base)
        let phase = (time * settings.speed / 6).truncatingRemainder(dividingBy: 1) * .pi * 2
        let accent = settings.accent.rgb
        let a = CGColor(red: accent.0, green: accent.1, blue: accent.2, alpha: 1)
        let b = CGColor(red: 0.10, green: 0.85, blue: 0.89, alpha: 1)
        let c = CGColor(red: 0.95, green: 0.27, blue: 0.67, alpha: 1)
        gradient(context, colors: [rgb(0.045, 0.05, 0.12), rgb(0.015, 0.02, 0.035)],
                 from: .zero, to: CGPoint(x: 1000, y: 2166))
        context.setAlpha(settings.intensity)
        switch settings.wallpaper {
        case .aurora:
            for index in 0..<5 {
                let n = Double(index)
                let x = 500 + sin(phase + n * 1.3) * 420
                let y = 850 + cos(phase + n * 0.9) * 530
                glow(context, center: CGPoint(x: x, y: y), radius: 760 - n * 55,
                     color: index.isMultiple(of: 2) ? a : b, alpha: 0.55)
            }
            for index in 0..<22 {
                let n = Double(index)
                let path = CGMutablePath()
                path.move(to: CGPoint(x: -100, y: 1450 + n * 14))
                path.addCurve(to: CGPoint(x: 1100, y: 650 + n * 19),
                              control1: CGPoint(x: 230 + sin(phase) * 180, y: 1250),
                              control2: CGPoint(x: 580 + cos(phase) * 150, y: 350 + n * 18))
                context.addPath(path)
                context.setStrokeColor(a.copy(alpha: 0.06)!)
                context.setLineWidth(2)
                context.strokePath()
            }
        case .liquid:
            for index in 0..<7 {
                let n = Double(index)
                let center = CGPoint(x: 500 + sin(phase + n * 1.4) * 290,
                                     y: 1000 + cos(phase + n * 1.1) * 620)
                let radius = 180 + sin(phase + n) * 40
                context.saveGState()
                context.translateBy(x: center.x, y: center.y)
                context.rotate(by: phase * (index.isMultiple(of: 2) ? 1 : -1))
                let rect = CGRect(x: -radius, y: -radius * 1.45, width: radius * 2, height: radius * 2.9)
                context.addEllipse(in: rect)
                context.clip()
                gradient(context, colors: [index.isMultiple(of: 2) ? a : b, c, rgb(0.1, 0.06, 0.24)],
                         from: CGPoint(x: -radius, y: -radius), to: CGPoint(x: radius, y: radius))
                context.restoreGState()
            }
        case .orbit:
            glow(context, center: CGPoint(x: 500, y: 1083), radius: 850, color: a, alpha: 0.4)
            for index in 0..<9 {
                let n = Double(index)
                context.saveGState()
                context.translateBy(x: 500, y: 1083)
                context.rotate(by: n * 0.24 + sin(phase) * 0.35)
                let radius = 120 + n * 48
                context.setStrokeColor((index.isMultiple(of: 2) ? a : b).copy(alpha: 0.65)!)
                context.setLineWidth(index.isMultiple(of: 3) ? 6 : 2)
                context.strokeEllipse(in: CGRect(x: -radius, y: -radius * 0.58, width: radius * 2, height: radius * 1.16))
                let x = cos(phase + n * 0.7) * radius
                let y = sin(phase + n * 0.7) * radius * 0.58
                context.setFillColor(rgb(0.94, 0.98, 1))
                context.fillEllipse(in: CGRect(x: x - 7, y: y - 7, width: 14, height: 14))
                context.restoreGState()
            }
            glow(context, center: CGPoint(x: 500, y: 1083), radius: 120, color: b, alpha: 0.95)
        case .prism:
            glow(context, center: CGPoint(x: 600, y: 800), radius: 850, color: c, alpha: 0.5)
            for index in 0..<12 {
                let n = Double(index)
                context.saveGState()
                context.translateBy(x: 500 + sin(phase + n) * 100, y: 1083 + cos(phase + n) * 100)
                context.rotate(by: n * 0.15 + sin(phase) * 0.2)
                let r = 650 - n * 42
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: -r))
                path.addLine(to: CGPoint(x: r * 0.866, y: r * 0.5))
                path.addLine(to: CGPoint(x: -r * 0.866, y: r * 0.5))
                path.closeSubpath()
                context.addPath(path)
                context.setStrokeColor((index.isMultiple(of: 2) ? a : b).copy(alpha: 0.8)!)
                context.setLineWidth(5)
                context.strokePath()
                context.restoreGState()
            }
        case .grid:
            let horizon = 1050.0
            glow(context, center: CGPoint(x: 500, y: horizon), radius: 650, color: a, alpha: 0.5)
            context.saveGState()
            context.addEllipse(in: CGRect(x: 280, y: 650, width: 440, height: 440))
            context.clip()
            gradient(context, colors: [c, a], from: CGPoint(x: 500, y: 650), to: CGPoint(x: 500, y: 1100))
            context.restoreGState()
            context.setStrokeColor(a.copy(alpha: 0.65)!)
            context.setLineWidth(2)
            for index in -12...12 {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 500 + Double(index) * 25, y: horizon))
                path.addLine(to: CGPoint(x: 500 + Double(index) * 210, y: 2166))
                context.addPath(path)
                context.strokePath()
            }
            // Phase wraps by exactly one row, keeping the grid continuous.
            for index in 0..<18 {
                let position = (Double(index) + phase / (2 * .pi)) / 18
                let y = horizon + position * position * (2166 - horizon)
                context.setAlpha(settings.intensity * min(1, position * 6) * min(1, (1 - position) * 8))
                context.move(to: CGPoint(x: 0, y: y))
                context.addLine(to: CGPoint(x: 1000, y: y))
                context.strokePath()
            }
            context.setAlpha(settings.intensity)
        case .stardust:
            glow(context, center: CGPoint(x: 600, y: 1150), radius: 800, color: a, alpha: 0.35)
            for index in 0..<160 {
                let n = Double(index)
                let seed = n * 2.3999632297
                let radius = sqrt(n / 160) * 830
                let x = 500 + cos(seed + phase) * radius * 0.62
                let y = 1083 + sin(seed + phase) * radius
                let dot = 2 + (n.truncatingRemainder(dividingBy: 5)) * 0.7
                let alpha = 0.3 + 0.7 * (sin(phase + seed) + 1) / 2
                context.setFillColor((index.isMultiple(of: 4) ? b : a).copy(alpha: alpha)!)
                context.fillEllipse(in: CGRect(x: x, y: y, width: dot * 2, height: dot * 2))
            }
        }
        context.setAlpha(1)
        // A dark veil keeps the clock and controls readable.
        gradient(context, colors: [rgb(0, 0, 0, 0.4), rgb(0, 0, 0, 0), rgb(0, 0, 0, 0.45)],
                 from: .zero, to: CGPoint(x: 0, y: bounds.height))
    }

    static func image(size: CGSize, time: Double, settings: StudioSettings) -> CGImage? {
        guard size.width.isFinite, size.height.isFinite,
              size.width >= 1, size.height >= 1, size.width <= 8192, size.height <= 8192 else { return nil }
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                                      bitsPerComponent: 8, bytesPerRow: Int(size.width) * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        draw(in: context, size: size, time: time, settings: settings)
        return context.makeImage()
    }

    private static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
        CGColor(red: r, green: g, blue: b, alpha: a)
    }

    private static func gradient(_ context: CGContext, colors: [CGColor], from: CGPoint, to: CGPoint) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil) else { return }
        context.drawLinearGradient(gradient, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    private static func glow(_ context: CGContext, center: CGPoint, radius: Double, color: CGColor, alpha: Double) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: [color.copy(alpha: alpha)!, color.copy(alpha: 0)!] as CFArray,
                                        locations: [0, 1]) else { return }
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    }
}
