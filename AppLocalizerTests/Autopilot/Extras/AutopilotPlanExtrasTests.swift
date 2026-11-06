//
//  AutopilotPlanExtrasTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The plan's "Also make · optional": what each choice adds, what it
/// records, and what the footer says.
@MainActor
@Suite("Autopilot plan extras")
struct AutopilotPlanExtrasTests {
    private var plan: AutopilotPlan { StudioDebugRuns.plan }

    private func plan(artwork: AutopilotArtworkSize? = nil, preview: AutopilotPreviewLanguages? = nil) -> AutopilotPlan {
        var plan = plan
        plan.alsoMakes = AutopilotExtras(
            makesArtwork: artwork != nil, artworkSize: artwork ?? .headerAndSearch,
            makesAppPreview: preview != nil, previewLanguages: preview ?? .primary
        )
        return plan
    }

    @Test func bothAreOffByDefaultAndInRunsFromBefore() throws {
        #expect(plan.extras == nil)
        #expect(plan.alsoMakes.isEmpty)
        #expect(plan.artworkKinds.isEmpty)
        #expect(plan.recordingTargets.isEmpty)
        #expect(plan.extrasTitle == nil)

        // A plan saved before the extras decodes without them.
        var json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(plan)) as? [String: Any])
        json.removeValue(forKey: "extras")
        let decoded = try JSONDecoder().decode(AutopilotPlan.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.alsoMakes == AutopilotExtras())
    }

    @Test func theChoicesPersistWithThePlan() throws {
        let chosen = plan(artwork: .wide, preview: .all)
        let decoded = try JSONDecoder().decode(AutopilotPlan.self, from: JSONEncoder().encode(chosen))
        #expect(decoded.alsoMakes == AutopilotExtras(makesArtwork: true, artworkSize: .wide, makesAppPreview: true, previewLanguages: .all))
    }

    @Test func theArtworkIsAHeaderAndASearchImageOrOneWideImage() {
        #expect(plan(artwork: .headerAndSearch).artworkKinds == [.header, .search])
        #expect(plan(artwork: .wide).artworkKinds == [.wide])
        #expect(AutopilotArtworkKind.header.pixelSize == PixelSize(width: 3840, height: 1646))
        #expect(AutopilotArtworkKind.search.pixelSize == PixelSize(width: 3840, height: 2560))
        #expect(AutopilotArtworkKind.wide.pixelSize == PixelSize(width: 5244, height: 2950))
        #expect(AutopilotArtworkKind.wide.placementTypes == ["PRODUCT_PAGE_HEADER_ASSET", "APP_STORE_SEARCH_RESULTS_ASSET"])
    }

    /// Board 32: the header is the brand with no phone; search results
    /// and the 16:9 image show the search screen; a scene shows none.
    @Test func searchArtworkShowsTheSearchScreenAndTheHeaderNone() {
        #expect(plan.searchSlot == 2)
        #expect(AutopilotArtworkMaker.slots(for: .search, plan: plan) == [2])
        #expect(AutopilotArtworkMaker.slots(for: .header, plan: plan).isEmpty)
        #expect(AutopilotArtworkMaker.slots(for: .wide, plan: plan) == [2])
        var scene = plan
        scene.alsoMakes.artworkShows = .scene
        #expect(AutopilotArtworkKind.allCases.allSatisfy { AutopilotArtworkMaker.slots(for: $0, plan: scene).isEmpty })

        var noSearch = plan
        noSearch.screens.remove(at: 2)
        #expect(noSearch.searchSlot == 0)
    }

    @Test func thePrimaryLanguageIsRecordedOnIPhoneAndIPad() {
        let primary = plan(preview: .primary)
        #expect(primary.previewDisplays == [.iPhone, .iPad])
        #expect(primary.previewLocales == ["en-US"])
        #expect(primary.recordingTargets == [
            AutopilotRecordingTarget(displayType: .iPhone, locale: "en-US"),
            AutopilotRecordingTarget(displayType: .iPad, locale: "en-US"),
        ])
    }

    @Test func everyLanguageIsRecordedWhenEachLanguageIsCaptured() {
        var all = plan(preview: .all)
        #expect(all.previewLocales.count == 12)
        #expect(all.recordingTargets.count == 24)

        // Captured in the primary language only, other languages' App
        // Previews come from its recording.
        all.capturesEachLanguage = false
        #expect(all.previewLocales.count == 12)
        #expect(all.recordedLocales == ["en-US"])
        #expect(all.recordingTargets.count == 2)
    }

    @Test func appleWatchAndVisionProGetNoAppPreview() {
        var plan = StudioDebugRuns.everyDevicePlan
        plan.alsoMakes.makesAppPreview = true
        #expect(plan.previewDisplays == [.iPhone, .iPad])
    }

    @Test func aRunWaitsForItsRecordingsUnlessTheyreSkipped() {
        var run = StudioDebugRuns.run(.capture)
        run.plan.alsoMakes.makesAppPreview = true
        let iPhone = AutopilotRecordingTarget(displayType: .iPhone, locale: "en-US")
        let iPad = AutopilotRecordingTarget(displayType: .iPad, locale: "en-US")
        #expect(run.remainingRecordings == [iPhone, iPad])

        run.addRecording(AutopilotRecording(
            id: "r1", target: iPhone, fileID: "abc", pixelSize: PixelSize(width: 1320, height: 2868), seconds: 38,
            marks: [AutopilotRecordingMark(screenID: "today", seconds: 1)], receivedAt: .now
        ))
        #expect(run.remainingRecordings == [iPad])
        #expect(run.recording(for: iPhone)?.fileID == "abc")

        run.skipRecording(AutopilotRecordingSkip(target: iPad, reason: "The iPad simulator wouldn’t record.", reportedAt: .now))
        #expect(run.remainingRecordings.isEmpty)
        #expect(run.isSkipped(iPad))
        // Another language's App Preview falls back on the primary's recording.
        #expect(run.previewRecording(for: AutopilotRecordingTarget(displayType: .iPhone, locale: "de-DE"))?.fileID == "abc")
    }

    /// MB Admin's run left both recordings out (a refused command), and
    /// only the details said so: Record Again makes them once more, and
    /// Claude Code is started again for them.
    @Test func skippedRecordingsCanBeRecordedAgain() {
        var run = AutopilotTestFixtures.run(.capture)
        run.captures = []
        run.plan.alsoMakes.makesAppPreview = true
        AutopilotTestFixtures.captureAll(&run)
        let targets = run.plan.recordingTargets
        for target in targets {
            run.skipRecording(AutopilotRecordingSkip(target: target, reason: "kill -INT isn’t allowed.", reportedAt: .now))
        }
        #expect(run.skippedRecordings.count == targets.count)
        #expect(run.remainingRecordings.isEmpty)
        #expect(!run.assistantHasWork)

        run.recordSkippedAgain()
        #expect(run.skippedRecordings.isEmpty)
        #expect(run.remainingRecordings == targets)
        #expect(run.assistantHasWork, "Claude Code is started again to record")
        #expect(!run.isCaptureComplete)
    }

    /// MB Admin's first iPad recording showed nothing: the UI tests ran on
    /// clones of the simulator being recorded.
    @Test func recordingRunsTheTestsOnTheRecordedSimulator() {
        #expect(AutopilotRun.recordingHow.contains("-parallel-testing-enabled NO"))
        #expect(AutopilotRun.recordingHow.contains("say in its reason which test to hold longer"))
    }

    @Test func theFooterAddsTheExtrasAndTheirTime() {
        #expect(AutopilotEstimate.summary(for: plan(artwork: .headerAndSearch, preview: .all), design: .claudeDesign)
            == "120 captures in 12 languages, plus header and search artwork and an App Preview in every language"
            + " · about 25 min on this Mac, then about 6 min of design")
        #expect(AutopilotEstimate.summary(for: plan(preview: .primary), design: .none)
            == "120 captures in 12 languages, plus an App Preview in English (U.S.)"
            + " · about 17 min on this Mac, then about 3 min of design")
        #expect(AutopilotEstimate.summary(for: plan(artwork: .wide), design: .none)
            == "120 captures in 12 languages, plus one 16:9 header and search image"
            + " · about 15 min on this Mac, then about 2 min of design")
    }

    @Test(arguments: [(1, 2), (2, 2), (3, 2), (12, 10), (15, 12)])
    func recordingEveryLanguageScalesWithTheLanguages(languages: Int, minutes: Int) {
        var plan = plan(preview: .all)
        plan.localeCodes = ["en-US"] + (1..<languages).map { "l\($0)" }
        #expect(AutopilotEstimate.recordingMinutes(for: plan) == minutes)
    }
}
#endif
