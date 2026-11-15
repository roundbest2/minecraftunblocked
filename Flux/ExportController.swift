import Combine
import SwiftUI
import UIKit

@MainActor
final class ExportController: ObservableObject {
    @Published private(set) var isBusy = false
    @Published private(set) var progress = 0.0
    @Published private(set) var status = ""
    @Published private(set) var canCancel = true
    @Published private(set) var needsPhotoSettings = false
    @Published var message: String?
    @Published var shareItem: ExportFiles?
    private var shareFiles: ExportFiles?
    private var task: Task<Void, Never>?

    func start(_ kind: ExportKind, settings: StudioSettings) {
        guard !isBusy else { return }
        cleanSharedFiles()
        isBusy = true
        progress = 0
        canCancel = true
        needsPhotoSettings = false
        status = "Creating your wallpaper…"
        message = nil
        task = Task {
            var output: ExportFiles?
            defer {
                isBusy = false
                task = nil
            }
            do {
                if case .livePhoto = kind { try await PhotoSaver.requestAccess() }
                try Task.checkCancellation()
                let result = try await WallpaperExporter.shared.make(kind: kind, settings: settings) { [weak self] value in
                    Task { @MainActor in self?.progress = value }
                }
                output = result
                try Task.checkCancellation()
                if case .livePhoto = kind {
                    canCancel = false
                    status = "Saving to Photos…"
                    try await PhotoSaver.save(result)
                    result.cleanUp()
                    message = "Saved to Photos. In Settings → Wallpaper, add it from Live Photos. If iOS marks motion unavailable, use the still image; Lock Screen motion eligibility is controlled by iOS."
                } else {
                    shareFiles = result
                    shareItem = result
                }
            } catch is CancellationError {
                output?.cleanUp()
            } catch {
                output?.cleanUp()
                if let exportError = error as? ExportError, case .permission = exportError {
                    needsPhotoSettings = true
                }
                message = error.localizedDescription
            }
        }
    }

    func cancel() {
        guard canCancel else { return }
        status = "Cancelling…"
        task?.cancel()
    }

    func cleanSharedFiles() {
        shareFiles?.cleanUp()
        shareFiles = nil
    }
}

struct ActivitySheet: UIViewControllerRepresentable {
    let urls: [URL]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: urls, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
