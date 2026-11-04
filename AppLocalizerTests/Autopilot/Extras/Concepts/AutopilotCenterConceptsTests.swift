//
//  AutopilotCenterConceptsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Header concepts, apart from the screenshot directions: they arrive at
/// Design idea first and pages after, only from the picked templates (or
/// of different kinds, going freely), the person chooses one at Choose,
/// asks for changes to one, and Use These goes on to Localize, where the
/// chosen header is animated into a loop to watch.
@MainActor
@Suite("Header concepts, chosen apart from the direction")
struct AutopilotCenterConceptsTests {
    private let center = AutopilotTestFixtures.center()
    private let context: AutopilotContext
    private let appID = StudioDebugRuns.appID

    init() {
        context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
    }

    private var run: AutopilotRun? { center.run(for: appID) }

    /// Design in a header-only run, before any concept arrived.
    private static func designing(_ style: AutopilotArtworkStyle = .templates, motion: AutopilotArtworkMotion = .loop) -> AutopilotRun {
        var run = StudioDebugHeaderStyle.headerOnly(.design, style: style, motion: motion)
        run.concepts = nil
        return run
    }

    private static func idea(_ concept: AutopilotArtworkConcept) -> AutopilotArtworkConcept {
        var idea = concept
        idea.design = nil
        return idea
    }

    // MARK: - Design

    @Test func aConceptArrivesIdeaFirstThenItsPages() async throws {
        center.install(Self.designing())
        let moonrise = StudioDebugConcepts.fromTemplates[0]
        try await center.addConcept(Self.idea(moonrise), appID: appID, context: context)
        #expect(run?.conceptList.map(\.id) == ["A"])
        #expect(run?.designedConcepts.isEmpty == true)
        #expect(run?.log.last?.text == "Header concept 1 · Moonrise → idea sent to AppLocalizer")
        #expect(run?.conceptsLeft == 3)

        let pages = AutopilotArtworkConcept(
            id: "A", name: "Moonrise", metaphor: "", fitsBecause: "", json: "{}", design: StudioDebugWebArtwork.quietIndigo,
            source: .claudeDesign, receivedAt: AutopilotTestFixtures.now
        )
        let merged = try await center.addConcept(pages, appID: appID, context: context)
        #expect(merged.metaphor == moonrise.metaphor, "The idea's words stay")
        #expect(merged.template == .night)
        #expect(merged.isRecommended)
        #expect(run?.log.last?.text == "Header concept 1 · Moonrise → header and search artwork sent to AppLocalizer")
        #expect(run?.designedConcepts.map(\.id) == ["A"])
        #expect(run?.stage == .design, "Two concepts to come")

        for concept in StudioDebugConcepts.fromTemplates.dropFirst() {
            try await center.addConcept(concept, appID: appID, context: context)
        }
        #expect(run?.stage == .choose, "The person chooses the header")
        #expect(run?.art == nil)
    }

    @Test func eachConceptAdaptsAnotherPickedTemplate() async throws {
        center.install(Self.designing())
        var hero = StudioDebugConcepts.fromTemplates[0]
        hero.template = .hero
        #expect(await refusal(hero)?.hasPrefix("Each concept adapts one of the person’s templates: set template to") == true)

        try await center.addConcept(StudioDebugConcepts.fromTemplates[0], appID: appID, context: context)
        var again = StudioDebugConcepts.fromTemplates[1]
        again.template = .night
        let taken = try #require(await refusal(again))
        #expect(taken.hasPrefix("Moonrise already adapts night: make one concept per template, next"))
        #expect(taken.contains("land") && taken.contains("window"))

        for concept in StudioDebugConcepts.fromTemplates.dropFirst() {
            try await center.addConcept(concept, appID: appID, context: context)
        }
        center.update(appID) { $0.stage = .design }
        var fourth = StudioDebugConcepts.fromTemplates[2]
        fourth.id = "D"
        #expect(await refusal(fourth)?.hasPrefix("Every concept has arrived") == true)
    }

    @Test func goingFreelyTheConceptsDifferInKind() throws {
        var run = Self.designing(.free)
        run.plan.alsoMakes.artworkDirection = AutopilotArtworkDirection()
        run.concepts = [StudioDebugConcepts.free[0]]
        var place = StudioDebugConcepts.free[1]
        place.kind = .place
        #expect(throws: AutopilotError.self) { try AutopilotCenter.checkFits(place, in: run) }
        try AutopilotCenter.checkFits(StudioDebugConcepts.free[1], in: run)

        // What the person asked for comes first: kinds may repeat.
        run.plan.alsoMakes.artworkDirection.text = "Calm, like writing before bed"
        try AutopilotCenter.checkFits(place, in: run)
    }

    @Test func pagesSentAgainAreLaidOverTheOnesBefore() {
        var first = StudioDebugConcepts.fromTemplates[0]
        first.drafts = StudioDebugWebArtwork.fullBleed
        var header = AutopilotArtworkDesign()
        header.setPage("<html>new header</html>", for: .header)
        var next = first
        next.design = header
        next.drafts = nil
        next.beats = []
        let merged = AutopilotCenter.merging(next, into: first)
        #expect(merged.design?.page(for: .header) == "<html>new header</html>")
        #expect(merged.design?.page(for: .search) == StudioDebugWebArtwork.quietIndigo.page(for: .search))
        #expect(merged.drafts == first.drafts)
        #expect(merged.beats == first.beats)
    }

    @Test func aPageThatRenderedShowsUntilTheConceptsOwnCome() {
        var start = Self.designing()
        start.concepts = [Self.idea(StudioDebugConcepts.fromTemplates[0])]
        center.install(start)
        center.noteConceptDraft("<html>draft</html>", kind: .header, conceptID: "A", appID: appID)
        #expect(run?.conceptList.first?.stillDesign?.page(for: .header) == "<html>draft</html>")
        #expect(run?.designedConcepts.isEmpty == true, "A draft isn't the concept's pages")
    }

    @Test func designSaysWhatThePersonChoosesNext() {
        let both = StudioDebugHeaderStyle.choosingBoth
        #expect(both.choicesTitle == "1 of 3 screenshot directions and 1 of 3 headers")
        #expect(both.nextChoiceLine == """
        Next, you choose: 1 of 3 screenshot directions and 1 of 3 headers. Then AppLocalizer localizes, Claude Design \
        animates the header you chose into a 20-second loop, for you to watch and approve.
        """)
        let still = StudioDebugHeaderStyle.headerOnly(.design, style: .free, motion: .still)
        #expect(still.nextChoiceLine == "Next, you choose: 1 of 3 headers. Then AppLocalizer localizes.")
        #expect(still.expectedDirections == 0, "Only the header: no directions")
    }

    // MARK: - Choose

    @Test func useThisHeaderWaitsForAHeader() async {
        center.install(StudioDebugHeaderStyle.headerOnly(.choose))
        #expect(run?.canUseChoices == false)
        await center.useChoices(appID: appID, context: context)
        #expect(run?.stage == .choose)

        center.pickConcept("Z", appID: appID)
        #expect(run?.art == nil, "No such concept")
        center.pickConcept("B", appID: appID)
        #expect(run?.art == "B")
        #expect(run?.canUseChoices == true)
    }

    @Test func useTheseWaitsForADirectionToo() throws {
        var start = StudioDebugHeaderStyle.choosingBoth
        start.directionPick = nil
        center.install(start)
        #expect(run?.canUseChoices == false)
        let second = try #require(run?.directions.dropFirst().first)
        center.pickDirection(second.id, appID: appID)
        #expect(run?.directionToUse?.id == second.id)
        #expect(run?.canUseChoices == true)
    }

    @Test func usingTheHeaderStartsItsLoop() async throws {
        let holding = AutopilotTestFixtures.center(holdsStages: true)
        var start = StudioDebugHeaderStyle.headerOnly(.choose)
        start.art = "B"
        holding.install(start)
        await holding.useChoices(appID: appID, context: context)
        let run = try #require(holding.run(for: appID))
        #expect(run.stage == .localize)
        #expect(run.loopReview?.conceptID == "B")
        #expect(run.loopReview?.isAnimating == true)
        #expect(run.log.last?.text == "Using the Evening Hills header")
    }

    @Test func aStillHeaderHasNoLoop() async {
        let holding = AutopilotTestFixtures.center(holdsStages: true)
        var start = StudioDebugHeaderStyle.headerOnly(.choose, motion: .still)
        start.art = "A"
        holding.install(start)
        await holding.useChoices(appID: appID, context: context)
        #expect(holding.run(for: appID)?.loopReview == nil)
    }

    @Test func aNoteOnOneConceptSendsOnlyItBack() throws {
        center.install(StudioDebugHeaderStyle.headerOnly(.choose))
        center.requestConceptChanges("Warmer sky", conceptIDs: ["B"], forDirections: false, appID: appID)
        let revision = try #require(run?.revision)
        #expect(run?.stage == .design)
        #expect(revision.askedConcepts == ["B"])
        #expect(!revision.asksDirections)
        #expect(run?.log.last?.text == "Asked for changes to Evening Hills: “Warmer sky”")

        #expect(throws: AutopilotError.self) {
            try center.reviseConcept("A", design: nil, changeNotes: nil, isLast: true, appID: appID)
        }
        var header = AutopilotArtworkDesign()
        header.setPage("<html>warmer</html>", for: .header)
        try center.reviseConcept("B", design: header, changeNotes: "A warmer sky", isLast: true, appID: appID)
        let concept = try #require(run?.concept("B"))
        #expect(concept.isRevised && concept.changeNotes == "A warmer sky")
        #expect(concept.design?.page(for: .header) == "<html>warmer</html>")
        #expect(concept.design?.page(for: .search) == StudioDebugWebArtwork.dawnPanorama.page(for: .search), "The other page stays")
        #expect(run?.stage == .choose)
        #expect(run?.revision == nil)
        #expect(run?.log.last?.text == "Evening Hills revised → header and search artwork sent to AppLocalizer")
    }

    @Test func aNoteForEverythingWaitsForTheDirectionsToo() throws {
        center.install(StudioDebugHeaderStyle.choosingBoth)
        let ids = run?.conceptList.map(\.id) ?? []
        center.requestConceptChanges("Lighter", conceptIDs: ids, forDirections: true, appID: appID)
        #expect(run?.revision?.asksDirections == true)
        #expect(run?.log.last?.text == "Asked for changes: “Lighter”")
        for id in ids {
            try center.reviseConcept(id, design: nil, changeNotes: nil, isLast: true, appID: appID)
        }
        #expect(run?.stage == .design, "No direction revised yet")
        #expect(run?.log.last?.text == "Night Window revised → header and search artwork sent to AppLocalizer; more on the way")
    }

    @Test func anUnattendedRunTakesTheRecommendedHeader() {
        var start = StudioDebugHeaderStyle.headerOnly(.design)
        start.stage = .design
        center.install(start)
        center.takeRecommendedConcept(appID)
        #expect(run?.art == "A")
        #expect(run?.log.last?.text == "Took Claude Design’s recommended header, Moonrise: It ties the header to the icon right next to it.")
    }

    // MARK: - The loop

    @Test func localizeWaitsForTheAnimatedPages() async throws {
        var start = StudioDebugHeaderStyle.headerOnly(.choose)
        start.stage = .localize
        start.art = "A"
        start.loopReview = AutopilotLoopReview(conceptID: "A")
        center.install(start)
        await center.finishLocalizing(appID, context: context)
        #expect(run?.loopReview?.waitsToMake == true)
        #expect(run?.stage == .localize)
        #expect(run?.log.last?.text == "Sent to Claude Design: animate the Moonrise header into a 20-second loop")
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .animateHeader(conceptID: "A"))

        await #expect(throws: AutopilotError.self) {
            try await center.addLoop("B", design: StudioDebugWebArtwork.quietIndigo, changeNotes: nil, client: "Claude Code", appID: appID, context: context)
        }
    }

    @Test func aMotionCheckThatFailsAgainIsTakenWithAWarning() {
        var start = StudioDebugHeaderStyle.headerOnly(.choose)
        start.stage = .localize
        start.art = "A"
        start.loopReview = AutopilotLoopReview(conceptID: "A")
        center.install(start)
        #expect(!center.refusesMotion([], appID: appID))
        #expect(center.refusesMotion(["The name moves."], appID: appID), "Refused the first time")
        #expect(!center.refusesMotion(["The name moves."], appID: appID), "Taken after one retry")
        #expect(run?.loopReview?.motionWarnings == ["The name moves."])
        #expect(run?.log.last?.text == "Header loop taken after one retry: The name moves.")
        #expect(run?.log.last?.kind == .problem)
    }

    @Test func aLoopThatPassesIsApprovedWhenTheRunDoesntStop() {
        var start = StudioDebugHeaderStyle.headerOnly(.choose)
        start.stage = .localize
        start.art = "A"
        var review = AutopilotLoopReview(conceptID: "A")
        review.version = 1
        start.loopReview = review
        start.plan.stopsToWatchPreview = false
        center.install(start)
        center.finishMaking(appID, extras: Self.madeLoops, readyLine: "Ready")
        #expect(run?.stage == .ready)
        #expect(run?.loopReview?.approvedAt == AutopilotTestFixtures.now)
        #expect(run?.log.map(\.text).contains("Header loop v1 approved: every check passed") == true)
    }

    @Test func aLoopWithAFailedCheckStopsEvenUnattended() {
        var start = StudioDebugHeaderStyle.headerOnly(.choose)
        start.stage = .localize
        start.art = "A"
        var review = AutopilotLoopReview(conceptID: "A")
        review.version = 1
        start.loopReview = review
        start.plan.stopsToWatchPreview = false
        var progress = AutopilotExtrasProgress()
        progress.artworkTooLong = ["de-DE"]
        start.extrasProgress = progress
        center.install(start)
        center.finishMaking(appID, extras: Self.madeLoops, readyLine: "Ready")
        #expect(run?.stage == .watchPreview)
        #expect(run?.loopReview?.approvedAt == nil)
        #expect(run?.log.last?.text == "Header loop v1 needs a look: a check didn’t pass, so it isn’t approved as made")
        #expect(run?.watchTitle == "Watch the header loop")
        #expect(run?.approveTitle == "Approve Header Loop")
    }

    @Test func approvingTheLoopGoesToReviewAndPush() async {
        center.install(StudioDebugHeaderStyle.watching(version: 2))
        center.requestLoopChanges("Fewer stars", appID: appID)
        #expect(run?.loopReview?.request?.note == "Fewer stars")
        center.approvePreview(appID: appID)
        #expect(run?.stage == .watchPreview, "Waits for the new version")
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .reviseLoop(note: "Fewer stars"))

        center.update(appID) { $0.loopReview?.request = nil }
        center.approvePreview(appID: appID)
        #expect(run?.stage == .ready)
        #expect(run?.log.last?.text == "Header loop v2 approved · everything is in Review & Push")
    }

    @Test func theStagesSayWhatThePersonDoes() {
        let plan = StudioDebugHeaderStyle.headerOnly(.plan)
        #expect(plan.title(of: .choose, design: .claudeDesign) == "Choose a header")
        #expect(plan.title(of: .choose, design: .none) == "Choose a direction", "AppLocalizer’s starters have no concepts")
        #expect(plan.title(of: .watchPreview, design: .claudeDesign) == "Watch the header loop")
        #expect(StudioDebugHeaderStyle.choosingBoth.title(of: .choose, design: .claudeDesign) == "Choose direction and header")

        let still = StudioDebugHeaderStyle.headerOnly(.plan, motion: .still)
        #expect(still.watchSkipNote(design: .claudeDesign) == "Skipped · nothing moves in this run")
        #expect(plan.watchSkipNote(design: .claudeDesign) == nil)
        #expect(plan.designDetail(design: .claudeDesign) == "3 headers")
        #expect(StudioDebugHeaderStyle.shotStyle.designDetail(design: .claudeDesign) == "2 directions")
    }

    // MARK: - Helpers

    /// The loops made in English.
    private static var madeLoops: ScreenshotExtras {
        var extras = ScreenshotExtras(directionName: "Moonrise", madeAt: AutopilotTestFixtures.now, artworkSize: .headerAndSearch)
        extras.artwork = [AutopilotArtworkKind.header, .search].map { kind in
            ExtrasArtworkFile(kind: kind, locale: "en-US", fileID: "\(kind.rawValue)-sum", headline: "", fits: true, byteCount: 1000, checks: [])
        }
        return extras
    }

    /// Why `concept` is refused, or nil when it's taken.
    private func refusal(_ concept: AutopilotArtworkConcept) async -> String? {
        do {
            try await center.addConcept(concept, appID: appID, context: context)
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
#endif
