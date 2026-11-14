import SwiftUI
import UIKit

/// A display link draws only while a visible screen asks for motion.
struct WallpaperSurface: UIViewRepresentable {
    var settings: StudioSettings
    var animated: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    func makeUIView(context: Context) -> WallpaperCanvas {
        let view = WallpaperCanvas()
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ uiView: WallpaperCanvas, context: Context) {
        uiView.configure(settings: settings,
                         animate: animated && settings.animatePreviews && !reduceMotion && scenePhase == .active)
    }

    static func dismantleUIView(_ uiView: WallpaperCanvas, coordinator: ()) { uiView.stop() }
}

final class WallpaperCanvas: UIView {
    private var settings = StudioSettings()
    private var wantsAnimation = false
    private var displayLink: CADisplayLink?
    private var proxy: DisplayLinkProxy?
    private let startTime = CACurrentMediaTime()
    private var elapsed = 0.0
    private var powerObserver: NSObjectProtocol?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        backgroundColor = .black
        contentMode = .redraw
        powerObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main
        ) { [weak self] _ in self?.refresh() }
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }
    deinit {
        displayLink?.invalidate()
        if let observer = powerObserver { NotificationCenter.default.removeObserver(observer) }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window { contentScaleFactor = min(2, window.screen.scale) }
        refresh()
    }

    func configure(settings: StudioSettings, animate: Bool) {
        self.settings = settings
        wantsAnimation = animate
        refresh()
        setNeedsDisplay()
    }

    private func refresh() {
        let active = wantsAnimation && window != nil && !ProcessInfo.processInfo.isLowPowerModeEnabled
        guard active else { stop(); return }
        if displayLink == nil {
            let proxy = DisplayLinkProxy(owner: self)
            self.proxy = proxy
            let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick))
            displayLink = link
            link.add(to: .main, forMode: .common)
        }
        displayLink?.preferredFrameRateRange = CAFrameRateRange(
            minimum: 15, maximum: settings.highFrameRate ? 60 : 30,
            preferred: settings.highFrameRate ? 60 : 30)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        proxy = nil
    }

    fileprivate func step() {
        elapsed = CACurrentMediaTime() - startTime
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        WallpaperRenderer.draw(in: context, size: bounds.size, time: elapsed, settings: settings)
    }
}

private final class DisplayLinkProxy {
    weak var owner: WallpaperCanvas?
    init(owner: WallpaperCanvas) { self.owner = owner }
    @objc func tick() { owner?.step() }
}
