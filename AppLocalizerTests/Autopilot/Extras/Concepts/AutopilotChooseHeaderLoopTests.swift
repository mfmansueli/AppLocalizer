//
//  AutopilotChooseHeaderLoopTests.swift
//  AppLocalizerTests
//

#if DEBUG
import AppKit
import SwiftUI
import Testing
@testable import AppLocalizer

/// Choose a header in a Header 21:9 only run with Motion loop: the section
/// names the one place it makes, each concept plays the loop it got at
/// Design (in runs from before, they're stills until one is chosen), the
/// three cards share the sheet's width without pushing the page past it,
/// and the chosen loop goes straight on to Localize.
@MainActor
@Suite("Choose a header · Header 21:9 only, Motion loop")
struct AutopilotChooseHeaderLoopTests {
    private let appID = StudioDebugRuns.appID

    /// `headerLoopOnly` as a run from before: its concepts were never
    /// animated at Design.
    private static var fromBefore: AutopilotRun {
        var run = StudioDebugHeaderStyle.headerLoopOnly
        run.animatesConcepts = nil
        for index in run.conceptList.indices { run.concepts?[index].motion = nil }
        return run
    }

    @Test func theSectionNamesThePlaceTheRunMakes() {
        #expect(StudioDebugHeaderStyle.headerLoopOnly.plan.alsoMakes.artworkSize.placeTitle == "Header")
        #expect(StudioDebugHeaderStyle.headerOnly(.choose).plan.alsoMakes.artworkSize.placeTitle == "Header and search")
    }

    @Test func eachConceptPlaysItsLoop() throws {
        let run = StudioDebugHeaderStyle.headerLoopOnly
        #expect(run.conceptsToChoose.count == 3)
        #expect(run.conceptsToChoose.allSatisfy(run.playsLoop))
        #expect(AutopilotChooseStageView.conceptsFrom(run) == "Claude Design’s own concepts · each plays its 20-second loop")
        #expect(ScreenshotStudioModel.conceptLoopNote(plays: true, run: run) == "20-second loop · plays muted on repeat · ")
        #expect(ScreenshotStudioModel.conceptScopeNote(run).hasSuffix(
            "Its loop is made again from the changes. After Localize and check you watch the one you chose in every language."
        ))
        #expect(try #require(run.nextChoiceLine) == """
        Next, you choose: 1 of 3 headers, each playing its 20-second loop. Then AppLocalizer localizes the one you chose, \
        for you to watch and approve.
        """)
    }

    @Test func aRunFromBeforeShowsStillsUntilOneIsChosen() {
        let run = Self.fromBefore
        #expect(run.conceptsToChoose.count == 3, "Its stills are enough to choose")
        #expect(!run.conceptsToChoose.contains(where: run.playsLoop))
        #expect(AutopilotChooseStageView.conceptsFrom(run) == "Claude Design’s own concepts · still for now: the one you choose becomes a 20-second loop")
        #expect(ScreenshotStudioModel.conceptLoopNote(plays: false, run: run) == "Becomes a 20-second loop if you choose it · ")

        let still = AutopilotChooseStageView.conceptsFrom(StudioDebugHeaderStyle.headerOnly(.choose, style: .free, motion: .still))
        #expect(still == "Claude Design’s own concepts · header and search share one look")
    }

    /// Alba's sheet at its 960-pt minimum leaves 699 pt inside the page's
    /// padding; before it's measured, the page starts at 0.
    @Test func threeConceptsFitTheSheet() {
        let width = AutopilotChooseStageView.conceptWidth(in: 699)
        #expect(width * 3 + AutopilotChooseStageView.conceptSpacing * 2 <= 699)
        #expect(AutopilotChooseStageView.conceptWidth(in: 0) == 150)
    }

    /// Cards sized for a wider page (the 900 pt the stage used to start
    /// at) can't make the page wider than it's offered.
    @Test func cardsSizedForAWiderPageKeepThePageToItsWidth() {
        let cards = NSHostingController(rootView: AutopilotDesignCardsLayout(spacing: AutopilotChooseStageView.conceptSpacing) {
            ForEach(0..<3, id: \.self) { _ in Color.clear.frame(width: 293, height: 200) }
        })
        #expect(cards.sizeThatFits(in: CGSize(width: 699, height: 2000)).width == 699)
    }

    /// The loop the person chose by is v1: Localize doesn't wait for
    /// Claude Design to animate it.
    @Test func choosingAMovingHeaderGoesStraightToItsLoop() async throws {
        let center = AutopilotTestFixtures.center(holdsStages: true)
        let context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
        var start = StudioDebugHeaderStyle.headerLoopOnly
        start.art = "B"
        center.install(start)

        await center.useChoices(appID: appID, context: context)
        let used = try #require(center.run(for: appID))
        #expect(used.stage == .localize)
        #expect(used.loopReview?.conceptID == "B")
        #expect(used.loopReview?.version == 1)
        #expect(used.loopReview?.isAnimating == false)
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) != .animateHeader(conceptID: "B"))
    }

    @Test func aRunFromBeforeAnimatesTheChosenHeaderAfterLocalize() async {
        let center = AutopilotTestFixtures.center(holdsStages: true)
        let context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
        var start = Self.fromBefore
        start.art = "A"
        center.install(start)

        await center.useChoices(appID: appID, context: context)
        #expect(center.run(for: appID)?.loopReview?.isAnimating == true, "Still pages until Claude Design animates them")

        await center.finishLocalizing(appID, context: context)
        #expect(center.run(for: appID)?.loopReview?.waitsToMake == true)
        #expect(center.run(for: appID)?.log.last?.text == "Sent to Claude Design: animate the Ink Sky header into a 20-second loop")
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .animateHeader(conceptID: "A"))
    }
}
#endif
