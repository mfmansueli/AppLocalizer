//
//  AppPreviewMakerCutTests.swift
//  AppLocalizerTests
//

import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import Testing
@testable import AppLocalizer

/// What a revision changes in the App Preview (its cut: which screens in
/// what order, how long, the captions' size) and the music under it.
@Suite("App Preview maker · cut and music")
struct AppPreviewMakerCutTests {
    private static let red = TemplateColor(red: 1, green: 0, blue: 0)
    private static let green = TemplateColor(red: 0, green: 1, blue: 0)
    private static let blue = TemplateColor(red: 0, green: 0, blue: 1)
    private static let recordingSize = PixelSize(width: 330, height: 718)

    private let template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")

    private func request(recording: URL, output: URL, cut: AppPreviewCut = AppPreviewCut(), music: AppPreviewMusicSource? = nil) -> AppPreviewRequest {
        AppPreviewRequest(
            recording: recording, recordingSize: Self.recordingSize, recordingSeconds: 8,
            marks: [
                AutopilotRecordingMark(screenID: "plan", seconds: 0),
                AutopilotRecordingMark(screenID: "tasks", seconds: 2.5),
                AutopilotRecordingMark(screenID: "share", seconds: 5),
            ],
            screens: [
                AppPreviewScreen(id: "plan", headline: "Plan your week in seconds"),
                AppPreviewScreen(id: "tasks", headline: "Every task in one place"),
                AppPreviewScreen(id: "share", headline: "Share it with your family"),
            ],
            template: template, locale: .englishUS, appName: "Lumen", displayType: .iPhone, output: output, cut: cut, music: music
        )
    }

    /// Red until 2.5 s, green until 5 s, then blue.
    private func recording() async throws -> URL {
        let url = AppPreviewTestRecording.temporaryURL("recording.mov")
        try await AppPreviewTestRecording.write(
            to: url, size: Self.recordingSize, seconds: 8, framesPerSecond: 10,
            scenes: [.init(start: 0, color: Self.red), .init(start: 2.5, color: Self.green), .init(start: 5, color: Self.blue)]
        )
        return url
    }

    /// Makes the App Preview with `cut` and `music`, then hands it to
    /// `check` before both files go.
    private func make(
        cut: AppPreviewCut = AppPreviewCut(), music: AppPreviewMusicSource? = nil, check: (AppPreviewResult, URL) async throws -> Void
    ) async throws {
        let recording = try await recording()
        let output = AppPreviewTestRecording.temporaryURL("preview.mov")
        defer {
            try? FileManager.default.removeItem(at: recording)
            try? FileManager.default.removeItem(at: output)
        }
        try await check(AppPreviewMaker.make(request(recording: recording, output: output, cut: cut, music: music)), output)
    }

    private func color(of url: URL, at seconds: Double, in result: AppPreviewResult) async throws -> TemplateColor? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let image = try await generator.image(at: CMTime(seconds: seconds, preferredTimescale: 600)).image
        let styler = AppPreviewStyler(template: template, locale: .englishUS, spec: result.spec, recordingSize: Self.recordingSize)
        return AppPreviewPixels.color(of: image, at: CGPoint(x: styler.appRect.midX, y: styler.appRect.midY))
    }

    @Test func theMusicPlaysUnderTheAppPreview() async throws {
        try await make(music: .track(.calmPiano)) { result, output in
            #expect(result.facts?.audioChannels == 2)
            let audio = try await AppPreviewMusicFile.samples(of: output)
            #expect(audio.contains { abs($0) > 0.05 }, "The App Preview isn't silent")
            #expect(Double(audio.count / 2) / AppPreviewSynth.sampleRate > result.output.seconds - 0.1)
        }
    }

    @Test func withoutMusicTheSoundTrackIsSilent() async throws {
        try await make { result, output in
            #expect(result.facts?.audioChannels == 2, "App Store Connect wants a sound track either way")
            await #expect(throws: AppPreviewError.silentMusic) { try await AppPreviewMusicFile.samples(of: output) }
        }
    }

    @Test func aRevisedCutPlaysItsScreensInItsOrder() async throws {
        let cut = AppPreviewCut(screenIDs: ["share", "plan"], seconds: 28)
        try await make(cut: cut) { result, output in
            #expect(result.segments.map(\.screenID) == ["share", "plan"], "Tasks is left out")
            #expect(result.spec.targetSeconds == 28)
            #expect(try await AppPreviewPixels.matches(color(of: output, at: 0.5, in: result), Self.blue, tolerance: 0.25))
            let second = try #require(result.segments.first?.duration) + 0.5
            #expect(try await AppPreviewPixels.matches(color(of: output, at: second, in: result), Self.red, tolerance: 0.25))
        }
    }

    @Test func aCutThatNamesNoPlannedScreenPlaysThePlansOrder() {
        let ids = ["plan", "tasks", "share"]
        #expect(AppPreviewCut(screenIDs: ["elsewhere"]).order(ids) == ids)
        #expect(AppPreviewCut(screenIDs: []).order(ids) == ids)
        #expect(AppPreviewCut(screenIDs: ["share", "share", "plan"]).order(ids) == ["share", "plan"])
        #expect(AppPreviewCut().order(ids) == ids)
    }

    @Test func theCutStaysWithinApplesRules() {
        #expect(AppPreviewCut().targetSeconds == Double(AutopilotExtras.previewSeconds))
        #expect(AppPreviewCut(seconds: 5).targetSeconds == 15)
        #expect(AppPreviewCut(seconds: 45).targetSeconds == 30)
        #expect(AppPreviewCut(captionScale: 3).captionScaleValue == 1.4)
        #expect(AppPreviewCut(captionScale: 0.2).captionScaleValue == 0.8)
        #expect(AppPreviewCut().isStandard)
        #expect(!AppPreviewCut(endCardShowsCaption: false).isStandard)
        #expect(!AppPreviewCut(endCardShowsCaption: false).showsEndCardCaption)
    }

    @Test func biggerCaptionsTakeMoreRoom() {
        let spec = AppPreviewSpec(displayType: .iPhone, pixelSize: PixelSize(width: 886, height: 1920))
        let standard = AppPreviewStyler(template: template, locale: .englishUS, spec: spec, recordingSize: Self.recordingSize)
        let bigger = AppPreviewStyler(
            template: template, locale: .englishUS, spec: spec, recordingSize: Self.recordingSize, captionScale: 1.4
        )
        #expect(bigger.captionScale == 1.4)
        #expect(bigger.captionRect.height > standard.captionRect.height, "The band grows with the captions")
    }
}
