//
//  AppPreviewMakerTests.swift
//  AppLocalizerTests
//

import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import Testing
@testable import AppLocalizer

/// A whole App Preview, from a recording to a file App Store Connect takes.
@Suite("App Preview maker")
struct AppPreviewMakerTests {
    private static let red = TemplateColor(red: 1, green: 0, blue: 0)
    private static let green = TemplateColor(red: 0, green: 1, blue: 0)
    private static let blue = TemplateColor(red: 0, green: 0, blue: 1)
    private static let recordingSize = PixelSize(width: 330, height: 718)

    private let template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")

    private func request(recording: URL, output: URL, display: ScreenshotDisplayType = .iPhone, marks: [AutopilotRecordingMark]? = nil) -> AppPreviewRequest {
        AppPreviewRequest(
            recording: recording, recordingSize: Self.recordingSize, recordingSeconds: 8,
            marks: marks ?? [
                AutopilotRecordingMark(screenID: "plan", seconds: 0),
                AutopilotRecordingMark(screenID: "tasks", seconds: 2.5),
                AutopilotRecordingMark(screenID: "share", seconds: 5),
            ],
            screens: [
                AppPreviewScreen(id: "plan", headline: "Plan your week in seconds"),
                AppPreviewScreen(id: "tasks", headline: "Every task in one place"),
                AppPreviewScreen(id: "share", headline: "Share it with your family"),
            ],
            template: template, locale: .englishUS, appName: "Lumen", displayType: display, output: output
        )
    }

    /// Red until 2.5 s, green until 5 s, then blue, at 10 frames a second.
    private func recording() async throws -> URL {
        let url = AppPreviewTestRecording.temporaryURL("recording.mov")
        try await AppPreviewTestRecording.write(
            to: url, size: Self.recordingSize, seconds: 8, framesPerSecond: 10,
            scenes: [.init(start: 0, color: Self.red), .init(start: 2.5, color: Self.green), .init(start: 5, color: Self.blue)]
        )
        return url
    }

    private func frame(of url: URL, at seconds: Double) async throws -> CGImage {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        return try await generator.image(at: CMTime(seconds: seconds, preferredTimescale: 600)).image
    }

    @Test func aRecordingBecomesAnAppPreviewAppStoreConnectTakes() async throws {
        let recording = try await recording()
        let output = AppPreviewTestRecording.temporaryURL("preview.mov")
        defer {
            try? FileManager.default.removeItem(at: recording)
            try? FileManager.default.removeItem(at: output)
        }
        let result = try await AppPreviewMaker.make(request(recording: recording, output: output))
        let facts = try #require(result.facts)
        #expect(result.issues.isEmpty, "\(result.issues)")
        #expect(result.isReady)
        #expect(facts.pixelSize == PixelSize(width: 886, height: 1920))
        #expect(facts.codec == .h264)
        #expect((15...30).contains(facts.seconds))
        #expect(facts.framesPerSecond <= 30.5)
        #expect(facts.audioChannels == 2)
        #expect(facts.byteCount > 0)
        #expect(facts.byteCount == result.output.byteCount)
        #expect(result.posterTimeCode == "00:00:05:00")
        #expect(result.segments.map(\.screenID) == ["plan", "tasks", "share"])
        #expect(abs(result.output.seconds - 15) < 0.05)
        #expect(abs(facts.seconds - result.output.seconds) < 0.05, "The sound track mustn't outlast the video")
        #expect(FileManager.default.fileExists(atPath: output.path))
    }

    @Test func eachScreenPlaysItsOwnStretchOfTheRecording() async throws {
        let recording = try await recording()
        let output = AppPreviewTestRecording.temporaryURL("preview.mov")
        defer {
            try? FileManager.default.removeItem(at: recording)
            try? FileManager.default.removeItem(at: output)
        }
        let result = try await AppPreviewMaker.make(request(recording: recording, output: output))
        let styler = AppPreviewStyler(template: template, locale: .englishUS, spec: result.spec, recordingSize: Self.recordingSize)
        let center = CGPoint(x: styler.appRect.midX, y: styler.appRect.midY)
        // plan plays 0–2.1 s, tasks 2.1–4.2 s, share 4.2–6.9 s, then the end card.
        let plan = try await frame(of: output, at: 1)
        let tasks = try await frame(of: output, at: 3)
        let share = try await frame(of: output, at: 5.5)
        let endCard = try await frame(of: output, at: 12)
        #expect(AppPreviewPixels.matches(AppPreviewPixels.color(of: plan, at: center), Self.red, tolerance: 0.25))
        #expect(AppPreviewPixels.matches(AppPreviewPixels.color(of: tasks, at: center), Self.green, tolerance: 0.25))
        #expect(AppPreviewPixels.matches(AppPreviewPixels.color(of: share, at: center), Self.blue, tolerance: 0.25))
        #expect(!AppPreviewPixels.matches(AppPreviewPixels.color(of: endCard, at: center), Self.blue, tolerance: 0.25))
    }

    @Test func noUsableMarkIsSaidPlainly() async throws {
        let output = AppPreviewTestRecording.temporaryURL("preview.mov")
        let marks = [AutopilotRecordingMark(screenID: "elsewhere", seconds: 1)]
        await #expect(throws: AppPreviewError.noUsableMark) {
            try await AppPreviewMaker.make(request(recording: output, output: output, marks: marks))
        }
        #expect(AppPreviewError.noUsableMark.errorDescription?.isEmpty == false)
    }

    @Test func aDeviceWithoutAppPreviewsIsRefused() async throws {
        let output = AppPreviewTestRecording.temporaryURL("preview.mov")
        await #expect(throws: AppPreviewError.noSpec(.watch)) {
            try await AppPreviewMaker.make(request(recording: output, output: output, display: .watch))
        }
    }

    @Test func aMissingRecordingIsUnreadable() async throws {
        let missing = AppPreviewTestRecording.temporaryURL("missing.mov")
        let output = AppPreviewTestRecording.temporaryURL("preview.mov")
        await #expect(throws: AppPreviewError.self) {
            try await AppPreviewMaker.make(request(recording: missing, output: output))
        }
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test func aCancelledRunLeavesNoFile() async throws {
        let recording = try await recording()
        let output = AppPreviewTestRecording.temporaryURL("preview.mov")
        defer { try? FileManager.default.removeItem(at: recording) }
        let request = request(recording: recording, output: output)
        let task = Task { try await AppPreviewMaker.make(request) }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }
}
