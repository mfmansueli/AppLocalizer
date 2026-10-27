//
//  CaptureFolderScannerTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import AppLocalizer

@Suite("CaptureFolderScanner")
struct CaptureFolderScannerTests {
    /// Writes the manifest and PNGs `xcresulttool` would export.
    private struct FakeAttachmentReader: XcresultAttachmentReader {
        func exportAttachments(of _: URL, to directory: URL) async throws {
            try CaptureFolderScannerTests.png(width: 1320, height: 2868, at: directory.appending(path: "A1.png"))
            let manifest = """
            [{"testIdentifier": "LumenUITests/testScreenshots()", "attachments": [
              {"exportedFileName": "A1.png", "suggestedHumanReadableName": "01_Today_0_9F2C1A3B-77D1.png",
               "deviceName": "iPhone 17 Pro Max", "configurationName": "German"},
              {"exportedFileName": "log.txt", "suggestedHumanReadableName": "log.txt"}
            ]}]
            """
            try Data(manifest.utf8).write(to: directory.appending(path: "manifest.json"))
        }
    }

    private struct FailingReader: XcresultAttachmentReader {
        func exportAttachments(of bundle: URL, to _: URL) async throws {
            throw CaptureImportError.xcresultUnreadable(bundle.lastPathComponent)
        }
    }

    static func png(width: Int, height: Int, at url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let context = try #require(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        let image = try #require(context.makeImage())
        let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
    }

    private func temporaryFolder() -> URL {
        URL.temporaryDirectory.appending(path: "CaptureScannerTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    private func scanner(_ reader: any XcresultAttachmentReader = FakeAttachmentReader()) -> CaptureFolderScanner {
        CaptureFolderScanner(reader: reader, homeDirectory: "/Users/sam", exportDirectory: temporaryFolder())
    }

    @Test func readsFastlaneOutputWithLocaleFoldersAndSizes() async throws {
        let root = temporaryFolder().appending(path: "screenshots")
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
        try Self.png(width: 132, height: 286, at: root.appending(path: "de-DE/iPhone 17 Pro Max-03_Search.png"))
        try Self.png(width: 132, height: 286, at: root.appending(path: "de-DE/iPhone 17 Pro Max-03_Search_framed.png"))
        try Data("<html/>".utf8).write(to: root.appending(path: "screenshots.html"))

        let scan = try await scanner().scan([root])
        #expect(scan.source == .fastlane)
        let file = try #require(scan.candidates.first)
        #expect(scan.candidates.count == 1)
        #expect(file.path == "de-DE/iPhone 17 Pro Max-03_Search.png")
        #expect(file.localeCode == "de-DE")
        #expect(file.deviceName == "iPhone 17 Pro Max")
        #expect(file.slotNumber == 3)
        #expect(file.pixelSize == PixelSize(width: 132, height: 286))
    }

    @Test func aDroppedLocaleFolderKeepsItsNameInThePath() async throws {
        let root = temporaryFolder().appending(path: "ja")
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
        try Self.png(width: 20, height: 40, at: root.appending(path: "01-Today.png"))
        let scan = try await scanner().scan([root])
        #expect(scan.source == .folder)
        #expect(scan.candidates.first?.path == "ja/01-Today.png")
        #expect(scan.candidates.first?.localeCode == "ja")
    }

    @Test func readsAResultBundleThroughItsExportedManifest() async throws {
        let bundle = temporaryFolder().appending(path: "Lumen.xcresult", directoryHint: .isDirectory)
        let scan = try await scanner().scan([bundle])
        #expect(scan.source == .xcodeResults)
        let file = try #require(scan.candidates.first)
        #expect(scan.candidates.count == 1)
        #expect(file.path == "Lumen.xcresult/01_Today_0_9F2C1A3B-77D1.png")
        #expect(file.localeCode == "de-DE")
        #expect(file.slotNumber == 1)
        #expect(file.slotName == "Today")
        #expect(file.deviceName == "iPhone 17 Pro Max")
    }

    @Test func aResultBundleItCantReadExplainsHowToExportIt() async {
        let bundle = temporaryFolder().appending(path: "Lumen.xcresult", directoryHint: .isDirectory)
        await #expect(throws: CaptureImportError.xcresultUnreadable("Lumen.xcresult")) {
            try await scanner(FailingReader()).scan([bundle])
        }
    }

    @Test func nothingToImportIsAnError() async throws {
        let root = temporaryFolder()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        await #expect(throws: CaptureImportError.noScreenshots) {
            try await scanner().scan([root])
        }
    }

    @Test func showsTheLocationUnderHomeWithATilde() async throws {
        let home = URL.temporaryDirectory.path(percentEncoded: false)
        let scanner = CaptureFolderScanner(reader: FakeAttachmentReader(), homeDirectory: home.hasSuffix("/") ? String(home.dropLast()) : home)
        let root = URL.temporaryDirectory.appending(path: "CaptureScannerTests-\(UUID().uuidString)/de-DE")
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
        try Self.png(width: 20, height: 40, at: root.appending(path: "1.png"))
        let scan = try await scanner.scan([root])
        #expect(scan.location.hasPrefix("~/CaptureScannerTests-"))
    }

    @Test func liveScreenshotsBecomeAnImportOfTheirSets() {
        let shot = LiveScreenshot(id: "s1", fileName: "1.png", pixelSize: PixelSize(width: 1320, height: 2868))
        let live = LiveScreenshots(screenshotSets: [
            LiveScreenshotSet(id: "a", locale: "de-DE", displayType: .iPhone, screenshots: [shot, shot]),
            LiveScreenshotSet(id: "b", locale: "de-DE", displayType: .watch, screenshots: [shot]),
        ])
        let scan = CaptureLiveCandidates.scan(live)
        #expect(scan.source == .appStoreConnect)
        #expect(scan.candidates.map(\.slotNumber) == [1, 2])
        let rows = CaptureMatcher(slotCount: 5).rows(for: scan.candidates)
        #expect(rows.compactMap(\.placement) == [
            CaptureMatchRow.Placement(locale: "de-DE", displayType: .iPhone, slot: 0),
            CaptureMatchRow.Placement(locale: "de-DE", displayType: .iPhone, slot: 1),
        ])
    }
}
