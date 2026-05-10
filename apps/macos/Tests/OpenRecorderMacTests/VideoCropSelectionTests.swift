import CoreGraphics
import XCTest
@testable import OpenRecorderMac

@MainActor
final class VideoCropSelectionTests: XCTestCase {
    func testPixelRectRoundTripsThroughNormalizedSelection() {
        let sourceSize = CGSize(width: 1920, height: 1080)
        let pixelRect = CGRect(x: 195, y: 115, width: 1725, height: 965)

        let selection = VideoCropSelection().withPixelRect(pixelRect, in: sourceSize)
        let roundTrip = selection.pixelRect(in: sourceSize)

        XCTAssertEqual(roundTrip.minX, 195, accuracy: 0.001)
        XCTAssertEqual(roundTrip.minY, 115, accuracy: 0.001)
        XCTAssertEqual(roundTrip.width, 1725, accuracy: 0.001)
        XCTAssertEqual(roundTrip.height, 965, accuracy: 0.001)
    }

    func testClampsTinyAndOutOfBoundsPixelRects() {
        let sourceSize = CGSize(width: 100, height: 80)

        let rect = VideoCropSelection.clampedPixelRect(
            CGRect(x: -20, y: 90, width: 3, height: 2),
            in: sourceSize
        )

        XCTAssertEqual(rect.minX, 0, accuracy: 0.001)
        XCTAssertEqual(rect.minY, 72, accuracy: 0.001)
        XCTAssertEqual(rect.width, 8, accuracy: 0.001)
        XCTAssertEqual(rect.height, 8, accuracy: 0.001)
    }

    func testDisplayAndPixelCropMappingUseFittedVideoFrame() {
        let sourceSize = CGSize(width: 1920, height: 1080)
        let availableSize = CGSize(width: 960, height: 720)
        let videoFrame = VideoCropGeometry.fittedVideoFrame(sourceSize: sourceSize, in: availableSize)
        let pixelRect = CGRect(x: 192, y: 108, width: 960, height: 540)

        let displayRect = VideoCropGeometry.displayRect(for: pixelRect, sourceSize: sourceSize, videoFrame: videoFrame)
        let roundTrip = VideoCropGeometry.pixelRect(for: displayRect, sourceSize: sourceSize, videoFrame: videoFrame)

        XCTAssertEqual(videoFrame.minX, 0, accuracy: 0.001)
        XCTAssertEqual(videoFrame.minY, 90, accuracy: 0.001)
        XCTAssertEqual(displayRect.minX, 96, accuracy: 0.001)
        XCTAssertEqual(displayRect.minY, 144, accuracy: 0.001)
        XCTAssertEqual(displayRect.width, 480, accuracy: 0.001)
        XCTAssertEqual(displayRect.height, 270, accuracy: 0.001)
        XCTAssertEqual(roundTrip.minX, pixelRect.minX, accuracy: 0.001)
        XCTAssertEqual(roundTrip.minY, pixelRect.minY, accuracy: 0.001)
        XCTAssertEqual(roundTrip.width, pixelRect.width, accuracy: 0.001)
        XCTAssertEqual(roundTrip.height, pixelRect.height, accuracy: 0.001)
    }

    func testExportOutputSizeUsesCropSourceDimensions() {
        let cropSize = CGSize(width: 1725, height: 965)

        let outputSize = VideoExportRenderer.resolvedOutputSize(
            for: cropSize,
            options: .default
        )

        XCTAssertEqual(outputSize.width, 1724, accuracy: 0.001)
        XCTAssertEqual(outputSize.height, 964, accuracy: 0.001)
    }

    func testExportOutputSizeScalesCroppedPresetByLongEdge() {
        let cropSize = CGSize(width: 1725, height: 965)
        let options = VideoExportOptions(
            resolution: .twoK,
            format: .mov,
            frameRate: .source,
            styling: .none,
            cropSelection: nil,
            customOutputSize: nil
        )

        let outputSize = VideoExportRenderer.resolvedOutputSize(for: cropSize, options: options)

        XCTAssertEqual(outputSize.width, 2560, accuracy: 0.001)
        XCTAssertEqual(outputSize.height, 1432, accuracy: 0.001)
    }

    func testExportOutputSizeHonorsCustomEvenDimensions() {
        let options = VideoExportOptions(
            resolution: .custom,
            format: .mov,
            frameRate: .source,
            styling: .none,
            cropSelection: nil,
            customOutputSize: CGSize(width: 1001, height: 777)
        )

        let outputSize = VideoExportRenderer.resolvedOutputSize(
            for: CGSize(width: 1920, height: 1080),
            options: options
        )

        XCTAssertEqual(outputSize.width, 1000, accuracy: 0.001)
        XCTAssertEqual(outputSize.height, 776, accuracy: 0.001)
    }

    func testRendererUsesNormalizedCropRectInSourcePixels() {
        let selection = VideoCropSelection(
            normalizedRect: CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.25),
            sizing: .preset(.source)
        )

        let rect = VideoExportRenderer.normalizedCropRect(
            for: selection,
            sourceSize: CGSize(width: 1920, height: 1080)
        )

        XCTAssertEqual(rect.minX, 192, accuracy: 0.001)
        XCTAssertEqual(rect.minY, 216, accuracy: 0.001)
        XCTAssertEqual(rect.width, 960, accuracy: 0.001)
        XCTAssertEqual(rect.height, 270, accuracy: 0.001)
    }
}
