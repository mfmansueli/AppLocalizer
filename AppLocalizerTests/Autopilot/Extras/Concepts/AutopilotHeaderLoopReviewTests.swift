//
//  AutopilotHeaderLoopReviewTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A Header 21:9 only run with Motion loop, from the header chosen to
/// Review & Push: Localize makes the chosen concept's header in every
/// language with its loop and saves it with the set, and Review & Push
/// lists it. When it can't be made, the run says so instead of calling it
/// ready, and Make Again makes it from the same choice.
@MainActor
@Suite("Header loop only · Review & Push", .serialized)
struct AutopilotHeaderLoopReviewTests {
    private let appID = StudioDebugRuns.appID
    private let center = AutopilotTestFixtures.center(holdsStages: true)
    private let services: DebugScreenshotsServices
    private let context: AutopilotContext

    init() {
        services = AutopilotTestFixtures.services(center)
        context = AutopilotTestFixtures.context(services)
    }

    /// `headerLoopOnly` with B chosen, in two languages so it's quick.
    private static var chosen: AutopilotRun {
        var run = StudioDebugHeaderStyle.headerLoopOnly
        run.art = "B"
        let primary = run.plan.primaryLocale
        run.plan.localeCodes = [primary] + run.plan.localeCodes.filter { $0 != primary }.prefix(1)
        return run
    }

    /// B's loop pages, past what a page may weigh: it can't be rendered.
    private static var tooHeavy: AutopilotRun {
        var run = chosen
        let heavy = "<!--" + String(repeating: "x", count: AutopilotArtworkDesign.maximumBytes) + "-->"
        let index = run.conceptList.firstIndex { $0.id == "B" } ?? 0
        run.concepts?[index].motion = AutopilotArtworkDesign(pages: [.header: heavy])
        return run
    }

    private var run: AutopilotRun? { center.run(for: appID) }

    private func savedExtras() async throws -> ScreenshotExtras? {
        try await services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS).extras
    }

    private func useAndLocalize(_ start: AutopilotRun) async {
        center.install(start)
        await center.useChoices(appID: appID, context: context)
        await center.finishLocalizing(appID, context: context)
    }

    @Test func theChosenHeaderWaitsInReviewAndPush() async throws {
        let start = Self.chosen
        await useAndLocalize(start)

        let log = run?.log.map(\.text).joined(separator: "\n") ?? ""
        let extras = try #require(try await savedExtras(), "Nothing saved:\n\(log)")
        #expect(extras.artwork.map(\.locale) == start.plan.localeCodes, "\(log)")
        #expect(extras.artwork.allSatisfy { $0.kind == .header && $0.loop != nil })
        #expect(run?.stage == .watchPreview)
        #expect(run?.extrasProgress?.artworkProblem == nil)
        let plan = try #require(ExtrasReviewFixtures.plan(extras, appID: appID), "Review & Push has nothing:\n\(log)")
        #expect(plan.artworkKinds == [.header])
        #expect(plan.items.map(\.artworkKind) == start.plan.localeCodes.map { _ in .header })
    }

    /// It used to say "Ready in Review & Push" with nothing there.
    @Test func aHeaderThatCouldntBeMadeIsntCalledReady() async throws {
        await useAndLocalize(Self.tooHeavy)

        let run = try #require(run)
        #expect(run.stage == .ready)
        let problem = try #require(run.extrasProgress?.artworkProblem)
        #expect(problem.contains("header page"))
        #expect(run.log.last?.kind == .problem)
        #expect(run.log.last?.text == "Header artwork couldn’t be made, so it isn’t in Review & Push; Make Again tries again with what you chose")
        let extras = try await savedExtras()
        #expect(AutopilotCenter.artworkMissing(run, extras: extras))
        #expect(ExtrasReviewFixtures.plan(extras ?? ScreenshotExtras(directionName: "", madeAt: .now), appID: appID) == nil)
    }

    @Test func makeAgainMakesItFromTheSameChoice() async throws {
        await useAndLocalize(Self.tooHeavy)
        // The page that failed, fixed: what a Make Again after this fix sees.
        var failed = try #require(run)
        let index = try #require(failed.conceptList.firstIndex { $0.id == "B" })
        failed.concepts?[index].motion = StudioDebugWebArtwork.quietIndigo
        center.install(failed)

        await center.makeExtrasAgain(appID: appID, context: context)

        let run = try #require(run)
        let log = run.log.map(\.text).joined(separator: "\n")
        #expect(run.stage == .watchPreview, "\(log)")
        #expect(run.chosenConcept?.id == "B", "Nothing is chosen again")
        #expect(run.extrasProgress?.artworkProblem == nil)
        #expect(log.contains("Making the header artwork again"))
        let extras = try #require(try await savedExtras())
        #expect(extras.artwork.map(\.locale) == failed.plan.localeCodes)
        #expect(!AutopilotCenter.artworkMissing(run, extras: extras))
    }

    @Test func makeAgainWaitsForAReadyRunThatMakesArtwork() async {
        var localizing = Self.chosen
        localizing.stage = .localize
        center.install(localizing)
        await center.makeExtrasAgain(appID: appID, context: context)
        #expect(run == localizing, "Not ready yet")

        var screenshotsOnly = StudioDebugRuns.run(.ready)
        screenshotsOnly.plan.alsoMakes = AutopilotExtras()
        center.install(screenshotsOnly)
        await center.makeExtrasAgain(appID: appID, context: context)
        #expect(run == screenshotsOnly, "No artwork to make")
    }

    /// A run that failed before `artworkProblem` was kept: the set has none
    /// of the kinds it makes.
    @Test func aRunFromBeforeWithoutItsArtworkIsMissingIt() {
        var ready = Self.chosen
        ready.stage = .ready
        let none = ScreenshotExtras(directionName: "Ink Sky", madeAt: .now)
        var kept = none
        kept.artwork = [ExtrasArtworkFile(kind: .search, locale: "en-US", fileID: "s", headline: "", fits: true, byteCount: 1)]
        var made = none
        made.artwork = [ExtrasArtworkFile(kind: .header, locale: "en-US", fileID: "h", headline: "", fits: true, byteCount: 1)]
        #expect(AutopilotCenter.artworkMissing(ready, extras: none))
        #expect(AutopilotCenter.artworkMissing(ready, extras: kept), "The search image kept from before isn't this run's")
        #expect(!AutopilotCenter.artworkMissing(ready, extras: made))
        #expect(!AutopilotCenter.artworkMissing(ready, extras: nil), "Not loaded yet")
        var watching = ready
        watching.stage = .watchPreview
        #expect(!AutopilotCenter.artworkMissing(watching, extras: none))
    }

    @Test func theReadyLineNamesWhatsMade() {
        var run = Self.chosen
        #expect(AutopilotCenter.readyLine(for: run) == "Ready in Review & Push: moving header artwork; the live screenshots stay as they are")
        run.extrasProgress = AutopilotExtrasProgress()
        run.extrasProgress?.artworkProblem = "Couldn’t render the header page in English (U.S.): The page didn’t load"
        let failed = "Header artwork couldn’t be made, so it isn’t in Review & Push; Make Again tries again with what you chose"
        #expect(AutopilotCenter.readyLine(for: run) == failed)

        var screenshots = StudioDebugRuns.run(.localize)
        screenshots.extrasProgress = run.extrasProgress
        let partly = "screenshots ready in Review & Push; header and search artwork couldn’t be made, Make Again tries again"
        #expect(AutopilotCenter.readyLine(for: screenshots).hasSuffix(partly))
    }
}
#endif
