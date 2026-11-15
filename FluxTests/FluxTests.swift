import XCTest
import AVFoundation
import ImageIO
@testable import Flux

final class FluxTests: XCTestCase {
    @MainActor
    func testPreferencesSurviveRelaunchAndReset() throws {
        let suite = "FluxTests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = StudioStore(defaults: defaults)
        original.settings.wallpaper = .prism
        original.settings.accent = .mint
        original.settings.speed = 1.7
        original.favorite(.stardust)
        let relaunched = StudioStore(defaults: defaults)
        XCTAssertEqual(relaunched.settings, original.settings)
        relaunched.reset()
        XCTAssertEqual(StudioStore(defaults: defaults).settings, StudioSettings())
    }

    @MainActor
    func testCorruptPreferencesRecoverWithoutCrashing() throws {
        let suite = "FluxTests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("invalid data".utf8), forKey: "flux.studio.settings.v1")
        XCTAssertEqual(StudioStore(defaults: defaults).settings, StudioSettings())
    }

    func testEveryWallpaperProducesNonblankSeamlessFrames() throws {
        for style in WallpaperStyle.allCases {
            var settings = StudioSettings()
            settings.wallpaper = style
            let first = try XCTUnwrap(WallpaperRenderer.image(size: CGSize(width: 120, height: 260), time: 0, settings: settings))
            let end = try XCTUnwrap(WallpaperRenderer.image(size: CGSize(width: 120, height: 260), time: 6, settings: settings))
            let startData = try XCTUnwrap(first.dataProvider?.data) as Data
            let endData = try XCTUnwrap(end.dataProvider?.data) as Data
            let middle = try XCTUnwrap(WallpaperRenderer.image(size: CGSize(width: 120, height: 260), time: 1.5, settings: settings))
            let middleData = try XCTUnwrap(middle.dataProvider?.data) as Data
            XCTAssertNotEqual(startData, middleData, style.title + " must visibly animate")
            XCTAssertEqual(startData, endData, style.title + " must loop")
            XCTAssertGreaterThan(Set(startData).count, 40, style.title + " must contain visible color")
        }
    }

    func testStillExportHasRequestedDimensions() async throws {
        let output = try await WallpaperExporter.shared.make(
            kind: .still, settings: StudioSettings(), size: CGSize(width: 240, height: 520), progress: { _ in })
        defer { output.cleanUp() }
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(output.files[0] as CFURL, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertEqual(image.width, 240)
        XCTAssertEqual(image.height, 520)
    }

    func testLivePhotoPairAndStillFrameMetadata() async throws {
        let output = try await WallpaperExporter.shared.make(
            kind: .livePhoto, settings: StudioSettings(), size: CGSize(width: 240, height: 520), progress: { _ in })
        defer { output.cleanUp() }
        XCTAssertEqual(output.files.count, 2)
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(output.files[0] as CFURL, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
        let maker = try XCTUnwrap(properties[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any])
        let stillIdentifier = try XCTUnwrap(maker["17"] as? String)
        let asset = AVURLAsset(url: output.files[1])
        let duration = try await asset.load(.duration)
        XCTAssertEqual(CMTimeGetSeconds(duration), 3, accuracy: 0.04)
        let metadata = try await asset.load(.metadata)
        let item = try XCTUnwrap(metadata.first { $0.identifier == .quickTimeMetadataContentIdentifier })
        let videoIdentifier = try await item.load(.stringValue)
        XCTAssertEqual(stillIdentifier, videoIdentifier)
        let tracks = try await asset.loadTracks(withMediaType: .metadata)
        let track = try XCTUnwrap(tracks.first)
        let reader = try AVAssetReader(asset: asset)
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        XCTAssertTrue(reader.canAdd(trackOutput))
        reader.add(trackOutput)
        let adaptor = AVAssetReaderOutputMetadataAdaptor(assetReaderTrackOutput: trackOutput)
        XCTAssertTrue(reader.startReading())
        let group = try XCTUnwrap(adaptor.nextTimedMetadataGroup())
        XCTAssertEqual(CMTimeGetSeconds(group.timeRange.start), 1.5, accuracy: 0.001)
        XCTAssertEqual(group.items.first?.key as? String, "com.apple.quicktime.still-image-time")
        reader.cancelReading()
    }

    func testVideoLoopDurationFollowsSpeed() async throws {
        var settings = StudioSettings()
        settings.speed = 2
        let output = try await WallpaperExporter.shared.make(
            kind: .movie, settings: settings, size: CGSize(width: 240, height: 520), progress: { _ in })
        defer { output.cleanUp() }
        let duration = try await AVURLAsset(url: output.files[0]).load(.duration)
        XCTAssertEqual(CMTimeGetSeconds(duration), 3, accuracy: 0.04)
    }

    func testCancellationDoesNotReturnAPartialFile() async {
        let task = Task {
            try await WallpaperExporter.shared.make(
                kind: .movie, settings: StudioSettings(), size: CGSize(width: 240, height: 520), progress: { _ in })
        }
        task.cancel()
        do {
            let output = try await task.value
            output.cleanUp()
            XCTFail("Cancelled export should throw.")
        } catch is CancellationError {
            // Expected: the partial output is removed by the exporter.
        } catch {
            XCTFail("Unexpected cancellation error: \(error)")
        }
    }
}
