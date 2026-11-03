//
//  AutopilotRunScopeFlowTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Each "What this run makes" preset through the whole run, as the center
/// drives it with AppLocalizer's starters: Capture (or the recording),
/// Pick, Design, Choose, then Localize to the end. The estimate and the
/// summary say what the rows chose, and header and search with "No app:
/// a scene" skips Capture and Pick.
@MainActor
@Suite("Autopilot run scope · each preset to the end")
struct AutopilotRunScopeFlowTests {
    private let appID = AutopilotTestFixtures.appID

    private static func plan(_ preset: AutopilotRunPreset, shows: AutopilotArtworkShow = .phone) -> AutopilotPlan {
        var plan = AutopilotTestFixtures.smallPlan
        preset.apply(to: &plan, devices: [.iPhone, .iPad], canReuse: false)
        plan.alsoMakes.artworkShows = shows
        plan.stopsToWatchPreview = false
        return plan
    }

    /// What a center needs for one run, its IDs unique: App Previews are
    /// made in the shared temporary folder under them.
    @MainActor
    private struct Harness {
        let center = AutopilotTestFixtures.center()
        let services: DebugScreenshotsServices
        let context: AutopilotContext

        init() {
            center.makeID = { UUID().uuidString }
            services = AutopilotTestFixtures.services(center)
            context = AutopilotTestFixtures.context(services)
        }
    }

    @Test(arguments: [AutopilotRunPreset.everything, .screenshots, .headerAndSearch, .appPreview])
    func eachPresetRunsToTheEnd(preset: AutopilotRunPreset) async throws {
        let harness = Harness()
        let center = harness.center
        let plan = Self.plan(preset)
        #expect(AutopilotRunPreset.matching(plan, devices: [.iPhone, .iPad]) == preset)
        center.prepare(appID: appID, versionString: "1.4", plan: plan)
        center.start(appID: appID)

        // Capture: the screenshots' (or the artwork's) screens, then the
        // App Preview's recordings.
        let step = await center.nextStep(appID: appID, client: AutopilotTestFixtures.client)
        let started = try #require(center.run(for: appID))
        #expect(started.stage == .capture)
        switch step {
        case let .capture(targets, _): #expect(!targets.isEmpty && !started.plan.targets.isEmpty)
        case let .record(targets): #expect(started.plan.targets.isEmpty && !targets.isEmpty)
        default: Issue.record("\(preset): expected capture or record, got \(step)")
        }
        #expect(started.plan.makesScreenshots == [.everything, .screenshots].contains(preset))
        #expect(started.plan.alsoMakes.makesArtwork == [.everything, .headerAndSearch].contains(preset))
        #expect(!started.plan.recordingTargets.isEmpty == [.everything, .appPreview].contains(preset))
        if preset == .headerAndSearch {
            #expect(Set(started.plan.targets.map(\.displayType)) == [.iPhone], "Only the artwork's screen, on iPhone")
        }

        try await Self.captureEverything(harness)
        await center.advance(appID, context: harness.context)
        let picking = try #require(center.run(for: appID))
        #expect(picking.stage == .pick)
        #expect(picking.picksMoments == !plan.recordingTargets.isEmpty)
        #expect(picking.picksScreens == !plan.targets.isEmpty)

        // Pick → Design → Choose, with AppLocalizer's starters.
        await center.usePicks(appID: appID, context: harness.context)
        let choosing = try #require(center.run(for: appID))
        #expect(choosing.stage == .choose)
        #expect(choosing.directions.count == AutopilotRun.directionCount)

        // Choose → Localize → the end.
        let direction = try #require(choosing.directions.first)
        await center.useDirection(direction.id, appID: appID, context: harness.context)
        try await Self.writeArtworkTexts(harness)
        let finished = try #require(center.run(for: appID))
        #expect(finished.stage == .ready, "\(preset): \(finished.log.suffix(3).map(\.text))")
        #expect((finished.templateVersion != nil) == plan.makesScreenshots, "Only screenshots make a template version")

        let extras = try await harness.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS).extras
        #expect((extras?.artwork.isEmpty == false) == plan.alsoMakes.makesArtwork)
        #expect((extras?.previews.isEmpty == false) == !plan.recordingTargets.isEmpty)
    }

    /// The estimate and the summary under the rows say what's chosen.
    @Test(arguments: [
        (AutopilotRunPreset.everything, "8 captures in 2 languages, plus header and search artwork and an App Preview in English (U.S.) · "),
        (.screenshots, "8 captures in 2 languages · "),
        (.headerAndSearch, "Header and search artwork in 2 languages · "),
        (.appPreview, "An App Preview in English (U.S.) · about "),
    ])
    func theEstimateMatchesTheRows(preset: AutopilotRunPreset, estimate: String) {
        let plan = Self.plan(preset)
        #expect(AutopilotEstimate.summary(for: plan, design: .none).hasPrefix(estimate))
        let makes = ScreenshotStudioModel.runMakes(plan)
        #expect(makes.contains("screenshots") == plan.makesScreenshots)
        #expect(makes.contains("header and search artwork") == plan.alsoMakes.makesArtwork)
        #expect(makes.contains("an App Preview for iPhone and iPad") == !plan.recordingTargets.isEmpty)
    }

    /// "No app: a scene" needs no capture: header and search alone has
    /// nothing to capture or pick and goes straight to the design.
    @Test func aSceneSkipsCaptureAndPick() async throws {
        let harness = Harness()
        let center = harness.center
        let plan = Self.plan(.headerAndSearch, shows: .scene)
        #expect(plan.targets.isEmpty)
        #expect(plan.recordingTargets.isEmpty)
        #expect(AutopilotEstimate.summary(for: plan, design: .none)
            == "Header and search artwork in 2 languages · nothing to capture on this Mac; about 2 min of design")
        center.prepare(appID: appID, versionString: "1.4", plan: plan)
        center.start(appID: appID)
        let waiting = try #require(center.run(for: appID))
        #expect(waiting.skipsCapture && waiting.skipsPick)
        #expect(waiting.captureSkipNote == "Skipped · nothing to capture")
        #expect(waiting.pickSkipNote == "Skipped · no new screenshots")

        await center.skipCapturingIfDone(appID, context: harness.context)
        let designed = try #require(center.run(for: appID))
        #expect(designed.stage == .choose, "AppLocalizer's starters, then the person chooses")
        #expect(designed.captures.isEmpty)
        #expect(designed.log.map(\.text).contains("Nothing to capture in this run"))

        let direction = try #require(designed.directions.first)
        await center.useDirection(direction.id, appID: appID, context: harness.context)
        try await Self.writeArtworkTexts(harness)
        #expect(center.run(for: appID)?.stage == .ready)
        let artwork = try await harness.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS).extras?.artwork ?? []
        #expect(!artwork.isEmpty)

        // With a phone, the artwork's screen is captured.
        let phone = Self.plan(.headerAndSearch, shows: .phone)
        #expect(!phone.targets.isEmpty)
    }

    // MARK: - Helpers

    /// Every capture, and a real recording of each recording target.
    private static func captureEverything(_ harness: Harness) async throws {
        let center = harness.center
        let appID = AutopilotTestFixtures.appID
        let size = AutopilotPreviewTestRun.recordingSize
        guard var run = center.run(for: appID) else { return }
        AutopilotTestFixtures.captureAll(&run)
        for target in run.plan.recordingTargets {
            let fileID = "test-recording-\(UUID().uuidString)"
            let marks = run.plan.screens.enumerated().map { AutopilotRecordingMark(screenID: $1.id, seconds: Double($0) * 3) }
            run.addRecording(AutopilotRecording(
                id: "rec-\(target.displayType.mcpValue)-\(target.locale)", target: target, fileID: fileID, pixelSize: size, seconds: 8,
                marks: marks, receivedAt: AutopilotTestFixtures.now
            ))
            let url = harness.services.recordingURL(fileID, for: AutopilotTestFixtures.app)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try await AppPreviewTestRecording.write(
                to: url, size: size, seconds: 8, framesPerSecond: 5,
                scenes: marks.map { .init(start: $0.seconds, color: TemplateColor(red: 0.2, green: 0.4, blue: 0.9)) }
            )
        }
        let finished = run
        center.update(appID) { $0 = finished }
    }

    /// The artwork's texts the assistant would write, when it's asked.
    private static func writeArtworkTexts(_ harness: Harness) async throws {
        let center = harness.center
        let appID = AutopilotTestFixtures.appID
        guard let run = center.run(for: appID), run.stage == .localize, let needs = run.artworkTextNeeds, !needs.isEmpty else { return }
        let updates = needs.map { AutopilotArtworkTextUpdate(locale: $0.locale, role: $0.role, headline: $0.role == .header ? "" : "Calm notes") }
        try await center.applyArtworkTexts(updates, client: AutopilotTestFixtures.client, appID: appID, context: harness.context)
    }
}
#endif
