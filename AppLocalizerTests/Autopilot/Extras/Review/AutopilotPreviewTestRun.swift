//
//  AutopilotPreviewTestRun.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
@testable import AppLocalizer

/// Lumen's run at Watch the App Preview for the tests: it makes only an
/// App Preview on iPhone in English (U.S.), from a small real recording of
/// its five screens, and the set is saved with the debug App Preview so
/// one made again can replace it.
@MainActor
enum AutopilotPreviewTestRun {
    static let recordingSize = PixelSize(width: 330, height: 718)

    /// Lumen's debug run at `stage`, making only an App Preview on iPhone
    /// in English (U.S.).
    static func run(_ stage: AutopilotStage) -> AutopilotRun {
        var run = StudioDebugExtras.run(stage, languages: .primary)
        run.plan.alsoMakes.makesArtwork = false
        run.plan.runChoice.previewDisplays = [.iPhone]
        if stage == .watchPreview { run.previewReview = AutopilotPreviewReview() }
        return run
    }

    /// Watching v1 with a recording on disk and the set saved, installed in
    /// `center`. The center's IDs become unique: the App Previews are made
    /// in the shared temporary folder under them, and tests run side by
    /// side.
    @discardableResult
    static func watching(
        center: AutopilotCenter, services: DebugScreenshotsServices, design: Bool = true, change: ((inout AutopilotRun) -> Void)? = nil
    ) async throws -> AutopilotRun {
        center.makeID = { UUID().uuidString }
        var run = run(.watchPreview)
        if !design { run.designKind = .none }
        change?(&run)
        let fileID = "test-recording-\(UUID().uuidString)"
        let marks = run.plan.screens.enumerated().map { AutopilotRecordingMark(screenID: $1.id, seconds: Double($0) * 1.6) }
        run.recordings = nil
        run.addRecording(AutopilotRecording(
            id: "rec-1", target: AutopilotRecordingTarget(displayType: .iPhone, locale: "en-US"), fileID: fileID,
            pixelSize: recordingSize, seconds: 8, marks: marks, receivedAt: AutopilotTestFixtures.now
        ))
        let url = services.recordingURL(fileID, for: AutopilotTestFixtures.app)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let colors = [TemplateColor(red: 1, green: 0, blue: 0), TemplateColor(red: 0, green: 1, blue: 0), TemplateColor(red: 0, green: 0, blue: 1)]
        try await AppPreviewTestRecording.write(
            to: url, size: recordingSize, seconds: 8, framesPerSecond: 5,
            scenes: marks.enumerated().map { .init(start: $1.seconds, color: colors[$0 % colors.count]) }
        )
        var document = try await services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        document.extras = StudioDebugExtras.extras(for: run)
        try await services.save(document, for: AutopilotTestFixtures.app)
        center.install(run)
        return run
    }
}
#endif
