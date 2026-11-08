//
//  ScreenshotStudioGuidedTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The guided Autopilot in the Studio: the front Settings chose, a new run
/// with the guided stops, What to make's cards, Ask for Changes on one look,
/// and Review & push's approvals.
@MainActor
@Suite("ScreenshotStudioModel · guided Autopilot")
struct ScreenshotStudioGuidedTests {
    private var appID: StoreApp.ID { StudioTestFixtures.app.id }

    private func screenshots(_ run: AutopilotRun? = nil) async -> (ScreenshotsViewModel, AutopilotCenter) {
        let center = StudioTestFixtures.center(run, project: StudioDebugRuns.northpier)
        return await (StudioTestFixtures.screenshots(center: center), center)
    }

    @Test func aNewGuidedRunStartsAtWhatToMake() async throws {
        let (model, center) = await screenshots()
        let studio = model.studio
        studio.guided.setupStep = .plan
        studio.runGuidedAutopilot()
        let run = try #require(center.run(for: appID))
        #expect(run.stage == .plan)
        #expect(!run.plan.stopsToPick)
        #expect(run.plan.stopsToChoose)
        #expect(run.plan.stopsToWatchPreview)
        #expect(studio.guided.setupStep == .make)
        #expect(studio.guidedStep == .make)
        #expect(studio.isAutopilotPresented)
    }

    @Test func aRunInProgressOpensWhereItIs() async {
        let (model, center) = await screenshots(StudioDebugGuided.designing(arrived: 1))
        let studio = model.studio
        studio.guided.showsDetails = true
        studio.runGuidedAutopilot()
        #expect(center.run(for: appID)?.stage == .design)
        #expect(studio.guided.showsDetails, "Nothing was reset")
        #expect(studio.guidedStep == .making)
    }

    @Test func theCardsChangeWhatThePlanMakes() async throws {
        let (model, center) = await screenshots(StudioDebugGuided.planned())
        let studio = model.studio
        studio.setGuidedMakes(.screenshots, false)
        studio.setGuidedMakes(.appPreview, false)
        let plan = try #require(center.run(for: appID)?.plan)
        #expect(!plan.makesScreenshots)
        #expect(!plan.alsoMakes.makesAppPreview)
        #expect(plan.alsoMakes.makesArtwork)
    }

    @Test func askingForChangesNamesTheLook() async throws {
        let (model, center) = await screenshots(StudioDebugGuided.choosing)
        let studio = model.studio
        let direction = try #require(center.run(for: appID)?.directions.first)
        studio.askForChanges("  bigger headline ", to: direction)
        let run = try #require(center.run(for: appID))
        #expect(run.stage == .design)
        #expect(run.revision?.note == "For “\(direction.name)”: bigger headline")
        #expect(run.revision?.forDirections == true)
        #expect(run.revision?.conceptIDs == nil, "The headers stay as they are")
    }

    @Test func anEmptyNoteAsksNothing() async throws {
        let (model, center) = await screenshots(StudioDebugGuided.choosing)
        let direction = try #require(center.run(for: appID)?.directions.first)
        model.studio.askForChanges("   ", to: direction)
        #expect(center.run(for: appID)?.stage == .choose)
    }

    @Test func theDirectionNoteNamesTheLook() {
        #expect(ScreenshotStudioModel.directionNote("bigger headline", name: "Night Ink") == "For “Night Ink”: bigger headline")
    }

    @Test func pushWaitsForEveryPart() async {
        let (model, _) = await screenshots(StudioDebugGuided.ready(approved: []))
        let studio = model.studio
        #expect(studio.guidedParts == [.screenshots, .artwork, .appPreview])
        #expect(studio.guidedShownPart == .screenshots)
        #expect(!studio.canPushGuided)

        studio.toggleApproval(.screenshots)
        #expect(studio.isApproved(.screenshots))
        #expect(studio.guided.reviewPart == .artwork, "On to the next part not approved")
        #expect(studio.guidedApprovedCount == 1)

        studio.toggleApproval(.artwork)
        studio.toggleApproval(.appPreview)
        #expect(studio.canPushGuided)

        studio.toggleApproval(.artwork)
        #expect(!studio.canPushGuided, "Taken back")
    }

    @Test func looksGoodConfirmsTheShortenedCaption() async throws {
        let (model, center) = await screenshots(StudioDebugGuided.ready(approved: []))
        let studio = model.studio
        let check = try #require(studio.guidedChecks(for: .screenshots).first { $0.state == .toConfirm })
        studio.confirmShortenings(check)
        #expect(center.run(for: appID)?.guidedReview?.confirmed == ["de-DE#2"])
        #expect(!studio.guidedChecks(for: .screenshots).contains { $0.state == .toConfirm })
    }

    @Test func reviewShowsTheRunsLanguages() async {
        let (model, _) = await screenshots(StudioDebugRuns.run(.ready))
        let studio = model.studio
        let locales = studio.guidedReviewLocales
        #expect(locales.first == "en-US")
        #expect(locales.count <= GuidedPreviewLocales.maximum)
        #expect(studio.guidedReviewLocale == "en-US")
        studio.guided.reviewLocale = "de-DE"
        #expect(studio.guidedReviewLocale == "de-DE")
        studio.guided.reviewLocale = "xx"
        #expect(studio.guidedReviewLocale == "en-US", "A language the run doesn't have")
    }

    @Test func aTemplateIsPreviewedInTheLanguageAsked() async {
        let (model, _) = await screenshots()
        let english = model.starterJobs(.cinema, locale: "en-US")
        let german = model.starterJobs(.cinema, locale: "de-DE")
        #expect(!german.isEmpty)
        #expect(german.count <= StarterPreview.slotCount)
        #expect(german.count == english.count)
        #expect(german.map(\.key) != english.map(\.key), "German captions, laid out in German")
        #expect(model.starterJobs(.cinema, locale: "xx").map(\.key) == english.map(\.key), "A language the app doesn't have shows the primary one")
    }
}
#endif
