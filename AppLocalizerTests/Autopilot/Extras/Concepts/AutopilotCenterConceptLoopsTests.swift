//
//  AutopilotCenterConceptLoopsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// With Motion loop, each header concept is animated at Design (runs
/// started since): it waits for its loop after its stills, its motion
/// checks get one retry of their own, the person chooses among the loops,
/// and a note on one makes its loop again.
@MainActor
@Suite("Header concepts animated at Design")
struct AutopilotCenterConceptLoopsTests {
    private let center = AutopilotTestFixtures.center()
    private let context: AutopilotContext
    private let appID = StudioDebugRuns.appID

    init() {
        context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
    }

    private var run: AutopilotRun? { center.run(for: appID) }

    /// Design with Motion loop in a run started since: each concept is
    /// animated before the person chooses.
    private static var animating: AutopilotRun {
        var run = StudioDebugHeaderStyle.headerOnly(.design)
        run.concepts = nil
        run.animatesConcepts = true
        return run
    }

    @Test func startingAMotionRunAnimatesEveryConcept() {
        var plan = StudioDebugHeaderStyle.headerOnly(.plan)
        plan.startedAt = nil
        center.install(plan)
        center.setDesignProject(StudioDebugRuns.northpier, for: appID)
        center.start(appID: appID)
        #expect(run?.proposesConcepts == true)
        #expect(run?.animatesConcepts == true)
        #expect(run?.animatesEachConcept == true)

        var still = StudioDebugHeaderStyle.headerOnly(.plan, motion: .still)
        still.startedAt = nil
        center.install(still)
        center.start(appID: appID)
        #expect(run?.animatesConcepts == nil, "Nothing moves")
    }

    @Test func eachConceptWaitsForItsLoop() async throws {
        center.install(Self.animating)
        for concept in StudioDebugConcepts.fromTemplates {
            try await center.addConcept(concept, appID: appID, context: context)
        }
        #expect(run?.stage == .design, "Their loops are to come")
        #expect(run?.designedConcepts.isEmpty == true)
        #expect(run?.conceptsToAnimate.map(\.id) == ["A", "B", "C"])
        #expect(run?.conceptsLeft == 3)
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .design(remaining: 0))

        try await center.addConceptMotion("A", design: StudioDebugWebArtwork.quietIndigo, client: "Claude Code", appID: appID, context: context)
        #expect(run?.log.last?.text == "Header concept 1 · Moonrise → 20-second loop sent by Claude Code")
        #expect(run?.designedConcepts.map(\.id) == ["A"])
        #expect(run?.stage == .design)

        for id in ["B", "C"] {
            try await center.addConceptMotion(id, design: StudioDebugWebArtwork.quietIndigo, client: "Claude Code", appID: appID, context: context)
        }
        #expect(run?.stage == .choose, "The person chooses among the loops")
        #expect(run?.conceptsToChoose.allSatisfy { run?.playsLoop(of: $0) == true } == true)
    }

    @Test func aLoopNeedsTheConceptsStillsFirst() async throws {
        var start = Self.animating
        var idea = StudioDebugConcepts.fromTemplates[0]
        idea.design = nil
        start.concepts = [idea]
        center.install(start)
        await #expect(throws: AutopilotError.self) {
            try await center.addConceptMotion("A", design: StudioDebugWebArtwork.quietIndigo, client: "Claude Code", appID: appID, context: context)
        }
        #expect(run?.conceptList.first?.motion == nil)

        // A run from before animates only the chosen header, later.
        var before = StudioDebugHeaderStyle.headerOnly(.design)
        before.concepts = StudioDebugConcepts.fromTemplates
        center.install(before)
        await #expect(throws: AutopilotError.self) {
            try await center.addConceptMotion("A", design: StudioDebugWebArtwork.quietIndigo, client: "Claude Code", appID: appID, context: context)
        }
    }

    @Test func aMotionCheckAtDesignIsRefusedOnceThenTakenWithAWarning() {
        var start = Self.animating
        start.concepts = StudioDebugConcepts.fromTemplates
        center.install(start)
        #expect(!center.refusesConceptMotion([], conceptID: "B", appID: appID))
        #expect(center.refusesConceptMotion(["The name moves."], conceptID: "B", appID: appID), "Refused the first time")
        #expect(!center.refusesConceptMotion(["The name moves."], conceptID: "B", appID: appID), "Taken after one retry")
        #expect(run?.concept("B")?.motionWarnings == ["The name moves."])
        #expect(run?.concept("A")?.motionRetries == nil, "Each concept has its own retry")
        #expect(run?.log.last?.text == "Evening Hills’s loop taken after one retry: The name moves.")
    }

    @Test func aNoteOnAMovingConceptMakesItsLoopAgain() async throws {
        var start = StudioDebugHeaderStyle.headerLoopOnly
        start.art = "A"
        center.install(start)
        center.requestConceptChanges("Warmer light", conceptIDs: ["B"], forDirections: false, appID: appID)
        #expect(run?.stage == .design)

        try center.reviseConcept("B", design: StudioDebugWebArtwork.fullBleed, changeNotes: "Warmer light", isLast: true, appID: appID)
        #expect(run?.stage == .design, "Its loop comes again from the new stills")
        #expect(run?.concept("B")?.motion == nil)
        #expect(run?.concept("A")?.motion != nil, "The others keep theirs")
        #expect(run?.log.last?.text == "Lamp-lit Window revised → header artwork sent to AppLocalizer; its loop is next")
        let revision = try #require(run?.revision)
        #expect(run?.conceptsLeft(for: revision) == ["B"])

        try await center.addConceptMotion("B", design: StudioDebugWebArtwork.quietIndigo, client: "Claude Code", appID: appID, context: context)
        #expect(run?.stage == .choose)
        #expect(run?.revision == nil)
    }
}
#endif
