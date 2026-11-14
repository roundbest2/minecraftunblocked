import AVFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation
import ImageIO
import Photos
import UniformTypeIdentifiers

enum ExportKind: Sendable { case still, movie, livePhoto }

struct ExportFiles: Identifiable, Sendable {
    let id = UUID()
    let folder: URL
    let files: [URL]
    let kind: ExportKind
    func cleanUp() { try? FileManager.default.removeItem(at: folder) }
}

enum ExportError: LocalizedError {
    case rendering, writer(String), permission, unavailable
    var errorDescription: String? {
        switch self {
        case .rendering: return "The image could not be rendered. Please try again."
        case .writer(let reason): return "The video could not be exported. " + reason
        case .permission: return "Allow Flux to add photos in iOS Settings, then try again. You can still share a still image or video without Photos access."
        case .unavailable: return "Photos could not save this Live Photo. Try sharing the still image or video instead."
        }
    }
}

actor WallpaperExporter {
    static let shared = WallpaperExporter()

    func make(kind: ExportKind, settings: StudioSettings,
              size: CGSize = CGSize(width: 1080, height: 2340),
              progress: @escaping @Sendable (Double) -> Void) async throws -> ExportFiles {
        let settings = settings.validated()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Flux-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            try Task.checkCancellation()
            if case .still = kind {
                let photo = folder.appendingPathComponent("Flux-" + settings.wallpaper.title + ".png")
                try writeImage(to: photo, size: size, time: 1.5, settings: settings, identifier: nil)
                try Task.checkCancellation()
                progress(1)
                return ExportFiles(folder: folder, files: [photo], kind: kind)
            }
            let identifier = UUID().uuidString
            let isLive: Bool
            if case .livePhoto = kind { isLive = true } else { isLive = false }
            let duration = isLive ? 3.0 : 6.0 / settings.speed
            let movie = folder.appendingPathComponent("Flux-" + settings.wallpaper.title + ".mov")
            try await writeMovie(to: movie, size: size, duration: duration, settings: settings,
                                 identifier: isLive ? identifier : nil, progress: progress)
            try Task.checkCancellation()
            if isLive {
                let photo = folder.appendingPathComponent("Flux-" + settings.wallpaper.title + ".jpg")
                try writeImage(to: photo, size: size, time: 1.5, settings: settings, identifier: identifier)
                return ExportFiles(folder: folder, files: [photo, movie], kind: kind)
            }
            return ExportFiles(folder: folder, files: [movie], kind: kind)
        } catch {
            try? FileManager.default.removeItem(at: folder)
            throw error
        }
    }

    private func writeImage(to url: URL, size: CGSize, time: Double,
                            settings: StudioSettings, identifier: String?) throws {
        guard let image = WallpaperRenderer.image(size: size, time: time, settings: settings),
              let destination = CGImageDestinationCreateWithURL(url as CFURL,
                  (identifier == nil ? UTType.png.identifier : UTType.jpeg.identifier) as CFString, 1, nil) else {
            throw ExportError.rendering
        }
        var properties: [String: Any] = [
            kCGImagePropertyOrientation as String: 1,
            kCGImageDestinationLossyCompressionQuality as String: 0.96
        ]
        if let identifier {
            properties[kCGImagePropertyMakerAppleDictionary as String] = ["17": identifier]
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ExportError.rendering }
    }

    private func writeMovie(to url: URL, size: CGSize, duration: Double, settings: StudioSettings,
                            identifier: String?, progress: @escaping @Sendable (Double) -> Void) async throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let width = Int(size.width), height = Int(size.height)
        let fps: Int32 = 30
        let count = Int((duration * Double(fps)).rounded())
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10_000_000,
                AVVideoExpectedSourceFrameRateKey: fps,
                AVVideoMaxKeyFrameIntervalKey: fps,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ],
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
            ]
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ])
        guard writer.canAdd(input) else { throw ExportError.writer("Video encoding is unavailable.") }
        writer.add(input)

        var metadataInput: AVAssetWriterInput?
        var metadataAdaptor: AVAssetWriterInputMetadataAdaptor?
        if let identifier {
            let contentID = AVMutableMetadataItem()
            contentID.identifier = .quickTimeMetadataContentIdentifier
            contentID.value = identifier as NSString
            contentID.dataType = kCMMetadataBaseDataType_UTF8 as String
            writer.metadata = [contentID]

            var format: CMMetadataFormatDescription?
            let specs: [[String: Any]] = [[
                kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String: "mdta/com.apple.quicktime.still-image-time",
                kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String: kCMMetadataBaseDataType_SInt8 as String
            ]]
            let status = CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
                allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed,
                metadataSpecifications: specs as CFArray, formatDescriptionOut: &format)
            guard status == noErr, let format else { throw ExportError.writer("Live Photo metadata is unavailable.") }
            let metadata = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil, sourceFormatHint: format)
            metadata.expectsMediaDataInRealTime = false
            guard writer.canAdd(metadata) else { throw ExportError.writer("Live Photo metadata cannot be encoded.") }
            writer.add(metadata)
            metadataInput = metadata
            metadataAdaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: metadata)
        }

        guard writer.startWriting() else { throw ExportError.writer(writer.error?.localizedDescription ?? "Could not start.") }
        writer.startSession(atSourceTime: .zero)
        do {
            if let metadataInput, let metadataAdaptor {
                try await waitUntilReady(metadataInput, writer: writer)
                let stillTime = AVMutableMetadataItem()
                stillTime.keySpace = .quickTimeMetadata
                stillTime.key = "com.apple.quicktime.still-image-time" as NSString
                stillTime.value = NSNumber(value: Int8(0))
                stillTime.dataType = kCMMetadataBaseDataType_SInt8 as String
                let group = AVTimedMetadataGroup(items: [stillTime],
                    timeRange: CMTimeRange(start: CMTime(value: 45, timescale: fps), duration: CMTime(value: 1, timescale: fps)))
                guard metadataAdaptor.append(group) else { throw ExportError.writer("Could not write the key frame marker.") }
                metadataInput.markAsFinished()
            }
            guard let pool = adaptor.pixelBufferPool else { throw ExportError.rendering }
            for frame in 0..<count {
                try Task.checkCancellation()
                try await waitUntilReady(input, writer: writer)
                try autoreleasepool {
                    var buffer: CVPixelBuffer?
                    guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &buffer) == kCVReturnSuccess,
                          let buffer else { throw ExportError.rendering }
                    let lockStatus = CVPixelBufferLockBaseAddress(buffer, [])
                    guard lockStatus == kCVReturnSuccess else { throw ExportError.rendering }
                    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
                    guard let context = CGContext(
                        data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                        bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
                    ) else { throw ExportError.rendering }
                    context.translateBy(x: 0, y: size.height)
                    context.scaleBy(x: 1, y: -1)
                    let renderTime = identifier == nil
                        ? Double(frame) / Double(count) * (6 / settings.speed)
                        : Double(frame) / Double(fps)
                    WallpaperRenderer.draw(in: context, size: size, time: renderTime, settings: settings)
                    guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: fps)) else {
                        throw ExportError.writer(writer.error?.localizedDescription ?? "A frame could not be written.")
                    }
                }
                if frame.isMultiple(of: 3) { progress(Double(frame + 1) / Double(count)) }
            }
            input.markAsFinished()
            writer.endSession(atSourceTime: CMTime(value: Int64(count), timescale: fps))
            await writer.finishWriting()
            try Task.checkCancellation()
            guard writer.status == .completed else {
                throw ExportError.writer(writer.error?.localizedDescription ?? "The export did not finish.")
            }
            progress(1)
        } catch {
            writer.cancelWriting()
            throw error
        }
    }

    private func waitUntilReady(_ input: AVAssetWriterInput, writer: AVAssetWriter) async throws {
        let deadline = Date().addingTimeInterval(20)
        while !input.isReadyForMoreMediaData {
            try Task.checkCancellation()
            guard writer.status == .writing, Date() < deadline else {
                throw ExportError.writer(writer.error?.localizedDescription ?? "The encoder stopped responding.")
            }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}

enum PhotoSaver {
    static func requestAccess() async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw ExportError.permission }
    }

    static func save(_ files: ExportFiles) async throws {
        guard files.files.count == 2, case .livePhoto = files.kind else { throw ExportError.unavailable }
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, fileURL: files.files[0], options: nil)
            request.addResource(with: .pairedVideo, fileURL: files.files[1], options: nil)
        }
    }
}
