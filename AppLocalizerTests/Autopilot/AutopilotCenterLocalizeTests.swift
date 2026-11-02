//
//  AutopilotCenterLocalizeTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Use This Direction and Localize and check: the set is saved as the next
/// template version, every language is checked, and the captions the
/// assistant writes are saved until everything fits.
@MainActor
@Suite("Autopilot localize and check")
struct AutopilotCenterLocalizeTests {
    private let center = AutopilotTestFixtures.center()
    private let services: DebugScreenshotsServices
    private let context: AutopilotContext
    private let appID = StudioDebugRuns.appID

    init() {
        services = AutopilotTestFixtures.services(center)
        context = AutopilotTestFixtures.context(services)
    }

    private var run: AutopilotRun? { center.run(for: appID) }

    private func savedDocument() async throws -> ScreenshotsDocument {
        try await services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
    }

    /// Choosing, in English and Thai: the sample has no Thai captions.
    private func useQuietIndigoWithThai() async {
        var start = StudioDebugRuns.run(.choose)
        start.plan.localeCodes = ["en-US", "th"]
        center.install(start)
        await center.useDirection("d-1", appID: appID, context: context)
    }

    @Test func usingADirectionSavesTheSetAsTheNextTemplateVersion() async throws {
        await useQuietIndigoWithThai()

        let run = try #require(run)
        #expect(run.chosenDirection?.name == "Quiet Indigo")
        #expect(run.handedBackAt == AutopilotTestFixtures.now, "Captions to shorten are the assistant's turn")
        #expect(run.templateVersion == 5)
        let document = try await savedDocument()
        #expect(document.history?.currentNumber == 5)
        #expect(document.template?.name == "Lumen Journal · Quiet Indigo")
        #expect(document.template?.slots.count == 5)
        #expect(document.slotNames == ScreenshotsSampleData.slotNames)
        #expect(document.scope.localized.isSuperset(of: ["th"]))
        let autopilot = document.captures.captures.filter { $0.source == .autopilot }
        #expect(autopilot.count == 10, "English on iPhone and iPad, five screens each")
        #expect(autopilot.contains { $0.fileName == "en-US/iPhone 17 Pro Max-01_Today.png" })
    }

    /// iPhone Duo's unfolded display captured sideways: the set's canvas
    /// turns landscape there, or every render would be cropped by half and
    /// fail its size check (Alba's 70 iPhone Duo renders). The other
    /// devices follow their captures too.
    @Test func theCanvasTurnsTheWayEachDevicesCapturesAre() async throws {
        var start = StudioDebugRuns.run(.choose)
        start.plan.localeCodes = ["en-US"]
        start.plan.setPlans(.iPhoneDuo, true)
        for (index, target) in start.plan.targets.filter({ $0.displayType == .iPhoneDuo }).enumerated() {
            var capture = AutopilotTestFixtures.capture(target, second: index)
            capture.pixelSize = CaptureSizeRules.duoInnerSize.rotated
            start.captures.append(capture)
        }
        center.install(start)
        await center.useDirection("d-1", appID: appID, context: context)

        let canvas = try #require(try await savedDocument().template?.canvas)
        #expect(canvas.orientation(for: .iPhoneDuo) == .landscape)
        #expect(canvas.orientation(for: .iPhone) == .portrait)
        #expect(canvas.orientation(for: .iPad) == .landscape, "The sample's iPad captures are landscape")
    }

    @Test func aDeviceKeepsTheDirectionsWayOnlyWithoutCaptures() {
        var run = StudioDebugRuns.run(.choose)
        for index in run.captures.indices where run.captures[index].target.displayType == .iPad {
            run.captures[index].pixelSize = ScreenshotDisplayType.iPad.portraitPixelSize
        }
        let canvas = AutopilotLocalizer.canvas(TemplateCanvas(iphone: .portrait, ipad: .landscape, duo: .landscape), matching: run)
        #expect(canvas.ipad == .portrait, "Its captures are portrait")
        #expect(canvas.duo == .landscape, "iPhone Duo isn't planned: the direction's way")
    }

    @Test func missingTranslationsGoToTheAssistant() async throws {
        await useQuietIndigoWithThai()

        let run = try #require(run)
        #expect(run.stage == .localize)
        #expect(run.overflows.map(\.locale) == Array(repeating: "th", count: 5))
        #expect(run.overflows.map(\.slot) == [0, 1, 2, 3, 4])
        #expect(run.overflows.allSatisfy { $0.headline.isEmpty && $0.displayType == .iPhone })
        #expect(run.localeStatus["th"] == .shortening(count: 5))
        #expect(run.localeStatus["en-US"]?.isDone == true)
        #expect(run.log.last?.text == "Sent to Claude Code: 5 captions to translate")
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .writeCaptions(run.overflows))
    }

    @Test func theWrittenCaptionsAreSavedAndTheSetIsReady() async throws {
        await useQuietIndigoWithThai()
        let captions = ["เขียนทุกวัน", "ทั้งสัปดาห์", "ค้นหาบันทึก", "รูปภาพของคุณ", "เป็นส่วนตัว"].enumerated().map { slot, headline in
            AutopilotCaptionUpdate(locale: "th", slot: slot, headline: headline)
        }
        try await center.applyCaptions(captions, client: AutopilotTestFixtures.client, appID: appID, context: context)

        let run = try #require(run)
        #expect(run.overflows.isEmpty)
        #expect(run.stage == .ready)
        #expect(run.finishedAt == AutopilotTestFixtures.now)
        #expect(run.shortenings.isEmpty, "Written captions aren't shortenings")
        #expect(run.log.map(\.text).contains("Claude Code wrote th slot 1: “เขียนทุกวัน”"))
        #expect(run.log.map(\.text).contains("Claude Code sent 5 captions; checking every language again"))
        #expect(run.log.last?.text == "20 screenshots ready in Review & Push")
        let saved = try await savedDocument().captions.caption(locale: "th", slot: 0)
        #expect(saved?.headline == "เขียนทุกวัน")
        #expect(saved?.provenance == .assistant(client: AutopilotTestFixtures.client, date: AutopilotTestFixtures.now))
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .done)
    }

    @Test func shortenedCaptionsAreListedForThePersonToCheck() async throws {
        let before = try #require(ScreenshotsTestFixtures.caption("de-DE", slot: 2)?.headline)
        var start = StudioDebugRuns.run(.localize)
        start.plan.localeCodes = ["en-US", "de-DE"]
        start.shortenings = []
        start.overflows = [AutopilotOverflow(locale: "de-DE", slot: 2, displayType: .iPhone, headline: before, maxLines: 2, fill: 1.3)]
        center.install(start)
        let shorter = AutopilotCaptionUpdate(locale: "de-DE", slot: 2, headline: "Einträge aus Jahren finden")
        try await center.applyCaptions([shorter], client: AutopilotTestFixtures.client, appID: appID, context: context)

        let run = try #require(run)
        #expect(run.shortenings == [
            AutopilotShortening(locale: "de-DE", slot: 2, before: before, after: "Einträge aus Jahren finden", client: AutopilotTestFixtures.client),
        ])
        #expect(run.log.map(\.text).contains("Claude Code wrote de-DE slot 3: “Einträge aus Jahren finden”"))
    }

    @Test func captionsAreRefusedOutsideLocalize() async {
        center.install(StudioDebugRuns.run(.choose))
        let update = AutopilotCaptionUpdate(locale: "de-DE", slot: 0, headline: "Hallo")
        await #expect(throws: AutopilotError("The run isn’t localizing now. Without run, propose_captions queues a proposal instead.")) {
            try await center.applyCaptions([update], client: AutopilotTestFixtures.client, appID: appID, context: context)
        }
    }

    @Test func aSetThatCantBeSavedGoesBackToTheChoice() async throws {
        let failing = FakeScreenshotsServices(document: ScreenshotsDebugDocuments.standard)
        failing.error = AutopilotError("The disk is full.")
        center.install(StudioDebugRuns.run(.choose))
        await center.useDirection("d-2", appID: appID, context: AutopilotTestFixtures.context(failing))

        let run = try #require(run)
        #expect(run.stage == .choose)
        #expect(run.chosenDirectionID == "d-2")
        #expect(run.log.last?.text == "Couldn’t save the set: The disk is full.")
        #expect(run.log.last?.kind == .problem)
    }

    @Test func anUnknownDirectionChangesNothing() async {
        let start = StudioDebugRuns.run(.choose)
        center.install(start)
        await center.useDirection("d-9", appID: appID, context: context)
        #expect(run == start)
    }
}
#endif
