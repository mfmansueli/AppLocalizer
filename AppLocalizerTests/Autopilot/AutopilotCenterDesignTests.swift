//
//  AutopilotCenterDesignTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Pick captures, Design and Choose: the person's picks, the design AI's
/// directions one by one (or AppLocalizer's starters), and Ask for
/// Changes.
@MainActor
@Suite("Autopilot picks and directions")
struct AutopilotCenterDesignTests {
    private let center = AutopilotTestFixtures.center()
    private let context: AutopilotContext
    private let appID = StudioDebugRuns.appID

    init() {
        context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
    }

    private var run: AutopilotRun? { center.run(for: appID) }

    /// The design AI's three directions for the sample run.
    private var northpierDirections: [AutopilotDirection] {
        StudioDebugRuns.directions(design: true, of: StudioDebugRuns.run(.design))
    }

    // MARK: - Pick

    @Test func thePersonPicksAmongTheCandidates() throws {
        center.install(StudioDebugRuns.run(.pick))
        let candidates = try #require(run).candidates(for: "today")
        #expect(candidates.map(\.attempt) == [1, 2, 3])
        #expect(run?.picks["today"] == candidates[0].id)

        center.pick(candidates[2].id, for: "today", appID: appID)
        #expect(run?.picks["today"] == candidates[2].id)
        #expect(run?.pickedCapture(for: "today")?.attempt == 3)

        center.pick("cap-de-DE-APP_IPHONE_67-today-1", for: "today", appID: appID)
        #expect(run?.picks["today"] == candidates[2].id, "Only the primary language's captures are candidates")
    }

    @Test func picksOnlyChangeAtPick() {
        let start = StudioDebugRuns.run(.choose)
        center.install(start)
        center.pick("cap-en-US-APP_IPHONE_67-today-3", for: "today", appID: appID)
        #expect(run?.picks == start.picks)
    }

    @Test func usingThePicksBriefsTheDesignAI() async throws {
        center.setDesignProject(StudioDebugRuns.northpier, for: appID)
        center.install(StudioDebugRuns.run(.pick))
        await center.usePicks(appID: appID, context: context)

        let run = try #require(run)
        #expect(run.stage == .design)
        #expect(run.handedBackAt == AutopilotTestFixtures.now, "The design AI's turn")
        #expect(run.directions.isEmpty)
        #expect(run.log.last?.text == "Brief ready for Northpier Brand: 5 captures, 12 languages")
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .design(remaining: 3))
    }

    @Test func withoutADesignProjectTheStartersAreMadeToChooseFrom() async throws {
        center.install(StudioDebugRuns.run(.pick, design: false))
        await center.usePicks(appID: appID, context: context)

        let run = try #require(run)
        #expect(run.stage == .choose)
        #expect(run.directions.map(\.id) == ["starter-above", "starter-band", "starter-panorama"])
        #expect(run.directions.allSatisfy { $0.source == .none && $0.client == nil && !$0.checks.isEmpty })
        #expect(run.directions.allSatisfy { $0.template.slots.count == 5 })
        #expect(run.log.map(\.text).contains("Direction 1 · Caption above device → template ready"))
    }

    // MARK: - Directions

    @Test func directionsArriveOneByOneThenThePersonChooses() async throws {
        center.install(StudioDebugRuns.run(.design))
        var second = northpierDirections[1]
        second.checks = []
        try await center.addDirection(second, appID: appID, context: context)
        #expect(run?.stage == .design)
        #expect(run?.log.last?.text == "Direction 2 · Full Bleed → template sent to AppLocalizer")
        #expect(run?.directions.last?.checks.isEmpty == false, "AppLocalizer checks every language")

        try await center.addDirection(northpierDirections[2], appID: appID, context: context)
        #expect(run?.stage == .choose)
        #expect(run?.directions.map(\.id) == ["d-1", "d-2", "d-3"])

        await #expect(throws: AutopilotError("The run isn’t designing now. Call next_step to see what AppLocalizer wants.")) {
            try await center.addDirection(northpierDirections[0], appID: appID, context: context)
        }
    }

    @Test func aFourthDirectionIsRefused() async throws {
        center.holdsStages = true
        var start = StudioDebugRuns.run(.design)
        start.directions = northpierDirections
        center.install(start)
        await #expect(throws: AutopilotError("Every direction has arrived. Revise one with revise_direction when next_step asks.")) {
            try await center.addDirection(northpierDirections[0], appID: appID, context: context)
        }
    }

    @Test func withoutStoppingToChooseTheFirstDirectionIsUsed() async throws {
        var start = StudioDebugRuns.run(.design)
        start.plan.stopsToChoose = false
        start.plan.localeCodes = ["en-US"]
        center.install(start)
        try await center.addDirection(northpierDirections[1], appID: appID, context: context)
        try await center.addDirection(northpierDirections[2], appID: appID, context: context)

        let run = try #require(run)
        #expect(run.chosenDirectionID == "d-1")
        #expect([AutopilotStage.localize, .ready].contains(run.stage))
        #expect(run.templateVersion == 5)
    }

    // MARK: - Ask for changes

    @Test func askingForChangesSendsTheNoteToTheDesignAI() async throws {
        center.install(StudioDebugRuns.run(.choose))
        center.requestRevision("   ", appID: appID)
        #expect(run?.stage == .choose)

        center.requestRevision("  Bigger headline, lighter indigo \n", appID: appID)
        let asked = try #require(run)
        #expect(asked.stage == .design)
        #expect(asked.revision == AutopilotRevisionRequest(note: "Bigger headline, lighter indigo", askedAt: AutopilotTestFixtures.now))
        #expect(asked.handedBackAt == AutopilotTestFixtures.now)
        #expect(asked.log.last?.text == "Asked for changes: “Bigger headline, lighter indigo”")
        await #expect(throws: AutopilotError("The person asked for changes: send them with revise_direction.")) {
            try await center.addDirection(northpierDirections[0], appID: appID, context: context)
        }
    }

    @Test func aRevisedDirectionGoesBackToTheChoice() async throws {
        center.install(StudioDebugRuns.run(.choose))
        center.requestRevision("Bigger headline", appID: appID)
        var template = northpierDirections[0].template
        template.caption.headline.size = 120

        let unknown = AutopilotError("No direction “d-9” in this run; it has d-1 (Quiet Indigo), d-2 (Full Bleed), or d-3 (Dawn Panorama).")
        await #expect(throws: unknown) {
            try await center.reviseDirection("d-9", template: template, rationale: nil, link: nil, appID: appID, context: context)
        }
        try await center.reviseDirection("d-1", template: template, rationale: "Bigger headline, as asked.", link: "", appID: appID, context: context)

        let run = try #require(run)
        #expect(run.stage == .choose)
        #expect(run.revision == nil)
        let revised = try #require(run.directions.first)
        #expect(revised.isRevised)
        #expect(revised.template.caption.headline.size == 120)
        #expect(revised.rationale == "Bigger headline, as asked.")
        #expect(revised.link == "https://claude.ai/design/northpier-brand/lumen-1", "An empty link keeps the old one")
        #expect(revised.receivedAt == AutopilotTestFixtures.now)
        #expect(run.log.last?.text == "Quiet Indigo revised → template sent to AppLocalizer")

        await #expect(throws: AutopilotError("No change was asked for. Call next_step to see what AppLocalizer wants.")) {
            try await center.reviseDirection("d-1", template: template, rationale: nil, link: nil, appID: appID, context: context)
        }
    }

    @Test func startersCantBeRevised() {
        center.install(StudioDebugRuns.run(.choose, design: false))
        center.requestRevision("Bigger headline", appID: appID)
        #expect(run?.stage == .choose)
        #expect(run?.revision == nil)
    }

    // MARK: - Progress

    /// Reading the brief shows the design started: the log says so once
    /// each time the person hands the design over, in that round's words.
    @Test func readingTheBriefIsLoggedOncePerHandOver() async {
        let clock = TestClock(AutopilotTestFixtures.now)
        center.now = { clock.now }
        center.setDesignProject(StudioDebugRuns.northpier, for: appID)
        center.install(StudioDebugRuns.run(.pick))
        await center.usePicks(appID: appID, context: context)
        clock.advance(by: 30)
        center.noteBriefRead(appID: appID, by: "Claude Code")
        #expect(run?.briefReadAt == clock.now)
        #expect(run?.log.last?.text == "Claude Code read the brief and is designing 3 directions")
        let lines = run?.log.count
        clock.advance(by: 60)
        center.noteBriefRead(appID: appID, by: "Claude Code")
        #expect(run?.briefReadAt == clock.now, "Each reading counts")
        #expect(run?.log.count == lines, "Logged once per hand-over")

        center.install(StudioDebugRuns.run(.choose))
        clock.advance(by: 60)
        center.requestRevision("Bigger headline", appID: appID)
        clock.advance(by: 10)
        center.noteBriefRead(appID: appID, by: "Claude Code")
        #expect(run?.log.last?.text == "Claude Code read the brief and is making your changes")
    }

    @Test func theBriefIsOnlyNotedWhileDesigning() {
        center.install(StudioDebugRuns.run(.choose))
        center.noteBriefRead(appID: appID, by: "Claude Code")
        #expect(run?.briefReadAt == nil)
        #expect(run?.log.count == StudioDebugRuns.run(.choose).log.count)
    }

    /// The design project's summary arriving while the run designs is in
    /// its log; at another stage it's only saved.
    @Test func readingTheDesignProjectIsLoggedWhileDesigning() {
        center.setDesignProject(StudioDebugRuns.northpier, for: appID)
        center.install(StudioDebugRuns.run(.design))
        center.setDesignSummary(DesignSourceSummary(title: "Alba · design system"), for: appID)
        #expect(run?.log.last?.text == "Read the design project: Alba · design system")

        center.install(StudioDebugRuns.run(.choose))
        center.setDesignSummary(DesignSourceSummary(title: "Alba · design system"), for: appID)
        #expect(run?.log.count == StudioDebugRuns.run(.choose).log.count)
        #expect(center.designProject(for: appID)?.summary?.title == "Alba · design system")
    }
}
#endif
