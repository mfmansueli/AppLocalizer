//
//  ScreenshotStudioModelTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Preview page's model: its header, preview and card on the loaded
/// sample, opening Autopilot, and which step the sheet shows.
@MainActor
@Suite("ScreenshotStudioModel")
struct ScreenshotStudioModelTests {
    // MARK: - Header

    @Test func withoutStoreTextsThePrimaryLanguageIsTheOnlyOne() async {
        let model = await StudioTestFixtures.screenshots(center: nil)
        #expect(model.studio.locales == [.englishUS])
        #expect(model.studio.selectedLocale == "en-US")
        model.studio.storeTexts = StudioStoreTexts(content: StorePageContentFixtures.editable)
        #expect(model.studio.locales.map(\.code) == ["en-US", "de-DE"])
    }

    @Test func choosingALanguageShowsIt() async {
        let model = await StudioTestFixtures.screenshots(center: nil)
        model.studio.selectedLocale = "ar-SA"
        #expect(model.studio.localeCode == "ar-SA")
        #expect(model.studio.preview.note == "Live now · Arabic falls back to English (U.S.)")
        #expect(model.studio.subtitle == "Version 1.4 · what people see before they download")
    }

    // MARK: - Preview and card

    @Test func newShowsTheSetWaitingInReviewAndPush() async {
        let model = await StudioTestFixtures.screenshots(center: nil)
        #expect(model.studio.hasNewSet)
        #expect(model.studio.summary.title == "Live set")
        model.studio.choice = .new
        #expect(model.studio.preview.note.hasPrefix("New set · "))
        #expect(model.studio.summary.title == "New set")
        let design = model.studio.summary.lines.first { $0.label == "Design" }?.value
        #expect(design?.hasSuffix(" · template v4") == true)
    }

    @Test func thePreviewFollowsTheDisplayType() async {
        let model = await StudioTestFixtures.screenshots(center: nil)
        model.displayType = .iPad
        model.renderQueue.cancel()
        #expect(model.studio.preview.displayType == .iPad)
        #expect(Array(model.studio.builder.slotNames.prefix(5)) == StudioTestFixtures.slotNames)
        #expect(model.studio.builder.slotNames.count >= 10)
    }

    @Test(arguments: [(ScreenshotDisplayType.iPhone, 320), (.iPad, 640)])
    func shotsRenderAtTwiceThePreviewsPoints(display: ScreenshotDisplayType, width: Int) {
        #expect(ScreenshotStudioModel.pixelWidth(for: display) == width)
    }

    @Test func liveImagesLoadAtPreviewWidth() async throws {
        let model = await StudioTestFixtures.screenshots(center: nil)
        model.studio.selectedLocale = "en-GB"
        let preview = model.studio.preview
        let shot = try #require(preview.shots.first)
        guard case let .live(live) = shot.image else {
            Issue.record("English (U.K.)'s hand-uploaded set should download")
            return
        }
        model.studio.loadImages(for: preview)
        #expect(await ScreenshotsTestWaiting.until { model.studio.renderQueue.liveImages[live.id] != nil })
        #expect(model.studio.image(for: shot)?.width == 320)
    }

    @Test func setsOpensTheSetsTab() async {
        let model = await StudioTestFixtures.screenshots(center: nil)
        model.tab = .preview
        model.studio.openSets()
        #expect(model.tab == .sets)
    }

    // MARK: - Autopilot

    @Test func runAutopilotPlansFromTheSetAndOpensTheSheet() async throws {
        let center = StudioTestFixtures.center()
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.storeTexts = StudioStoreTexts(content: StorePageContentFixtures.editable)
        model.studio.viewedStep = .pick
        model.studio.runAutopilot()
        let run = try #require(center.run(for: StudioTestFixtures.app.id))
        #expect(run.stage == .plan)
        #expect(run.versionString == "1.4")
        #expect(run.plan.screens.count == 5)
        #expect(run.plan.localeCodes == ["en-US", "de-DE"])
        #expect(run.createdAt == StudioTestFixtures.now)
        #expect(model.studio.isAutopilotPresented)
        #expect(model.studio.viewedStep == nil)
        #expect(model.studio.run == run)
    }

    @Test func withoutAutopilotNothingOpens() async {
        let model = await StudioTestFixtures.screenshots(center: nil)
        model.studio.runAutopilot()
        #expect(!model.studio.isAutopilotPresented)
        #expect(model.studio.run == nil)
        #expect(model.studio.designProject == nil)
    }

    @Test func openFollowsTheRun() async {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(StudioDebugRuns.run(.pick)))
        model.studio.viewedStep = .plan
        model.studio.openAutopilot()
        #expect(model.studio.isAutopilotPresented)
        #expect(model.studio.viewedStep == nil)
        #expect(model.studio.guidedStep == .making, "Pick captures shows in Making it")
    }

    @Test func theDesignProjectIsTheApps() async {
        let center = StudioTestFixtures.center(project: StudioDebugRuns.northpier)
        let model = await StudioTestFixtures.screenshots(center: center)
        #expect(model.studio.designProject?.displayName == "Northpier Brand")
    }

    @Test(arguments: [
        (AutopilotStage?.none, GuidedStep.make),
        (.plan, .make),
        (.waiting, .making),
        (.capture, .making),
        (.choose, .choose),
        (.ready, .review),
    ])
    func theSheetShowsTheRunsStep(stage: AutopilotStage?, shown: GuidedStep) async {
        let center = StudioTestFixtures.center(stage.map { StudioDebugRuns.run($0) })
        let model = await StudioTestFixtures.screenshots(center: center)
        #expect(model.studio.guidedStep == shown)
    }

    @Test func onlyStepsTheRunReachedCanBeViewed() async {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(StudioDebugRuns.run(.pick)))
        let viewable = AutopilotStage.steps.filter { model.studio.canView($0) }
        #expect(viewable == [.plan, .capture, .pick])
        #expect(model.studio.canView(.waiting))
        let fresh = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center())
        #expect(AutopilotStage.steps.filter { fresh.studio.canView($0) } == [.plan])
    }

    @Test func reachingReadyShowsTheNewSet() async {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(StudioDebugRuns.run(.ready)))
        model.studio.runDidChange(from: .localize, to: .localize)
        model.studio.runDidChange(from: .choose, to: .localize)
        #expect(model.studio.choice == .live)
        model.studio.runDidChange(from: .localize, to: .ready)
        #expect(await ScreenshotsTestWaiting.until { model.studio.choice == .new })
    }
}
#endif
