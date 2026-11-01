//
//  AutopilotStripContentTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The strip above the preview at each of a run's stages.
@MainActor
@Suite("AutopilotStripContent")
struct AutopilotStripContentTests {
    // MARK: - Idle

    @Test func withoutAnAssistantItOffersSetupAndImport() {
        let strip = Self.strip(nil, assistant: nil)
        #expect(strip.kind == .needsAssistant)
        #expect(strip.pill == "Needs an assistant")
        #expect(strip.text.hasPrefix("Capturing runs Lumen Journal in Simulator through an assistant that can use Xcode"))
        #expect(strip.primary == .setUpAssistant)
        #expect(strip.secondary == .importCaptures)
        #expect(!strip.showsConnections)
        #expect(strip.progress == nil)
    }

    @Test func anAssistantWithoutADesignProjectCanRunAutopilot() {
        let strip = Self.strip(nil)
        #expect(strip.kind == .idle)
        #expect(strip.title == "Screenshot Autopilot")
        #expect(strip.pill == "New")
        #expect(strip.text == "Claude Code runs Lumen Journal in Simulator and captures every screen in every language. "
            + "Your design project, if you connect one, designs the set in your brand. "
            + "AppLocalizer localizes, checks and keeps every step here.")
        #expect(strip.primary == .runAutopilot)
        #expect(strip.secondary == nil)
        #expect(strip.showsConnections)
    }

    @Test func aDesignProjectIsNamed() {
        let strip = Self.strip(nil, project: StudioDebugRuns.northpier)
        #expect(strip.text.contains(" Claude Design designs the set in Northpier Brand. "))
    }

    @Test func anEarlierRunDropsTheNewPill() {
        let plan = Self.strip(StudioDebugRuns.run(.plan))
        #expect(plan.kind == .idle)
        #expect(plan.pill == nil)
        let readyWithoutNewSet = Self.strip(StudioDebugRuns.run(.ready), hasNewSet: false)
        #expect(readyWithoutNewSet.kind == .idle)
        #expect(readyWithoutNewSet.pill == nil)
    }

    // MARK: - Running

    @Test func waitingForTheAssistantShowsALittleProgress() {
        let strip = Self.strip(StudioDebugRuns.run(.waiting))
        #expect(strip.kind == .running)
        #expect(strip.title == "Autopilot is running")
        #expect(strip.text == "Waiting for Claude Code to pick up the plan")
        #expect(strip.progress == 0.02)
        #expect(strip.pill == nil)
        #expect(strip.primary == .open)
        #expect(strip.secondary == nil)
        #expect(!strip.showsConnections)
        var unclaimed = StudioDebugRuns.run(.waiting)
        unclaimed.client = nil
        #expect(Self.strip(unclaimed).text == "Waiting for the assistant to pick up the plan")
    }

    @Test func capturingNamesTheLatestCaptureAndCounts() throws {
        let run = StudioDebugRuns.run(.capture)
        let strip = Self.strip(run)
        let latest = try #require(run.latestCapture)
        let language = try #require(StoreLocaleCatalog.locale(code: latest.target.locale)).shortName
        let screen = try #require(run.plan.screen(id: latest.target.screenID)).name
        #expect(strip.text == "Capturing · \(language) · \(latest.target.displayType.title) · \(screen) · 76 of 120")
        #expect(strip.progress == 76.0 / 120.0)
    }

    @Test(arguments: [(1, "1 problem"), (2, "2 problems")])
    func problemsShowAsARedPill(count: Int, pill: String) {
        var run = StudioDebugRuns.failing
        if count == 2 {
            var second = run.problems[0]
            second.id = "pr-second"
            second.target.screenID = "week"
            run.problems.append(second)
        }
        let strip = Self.strip(run)
        #expect(strip.pill == pill)
        #expect(strip.pillStyle == .danger)
        // A problem the person answered isn't counted.
        run.problems[0].resolution = .retryWithFix
        #expect(Self.strip(run).pill == (count == 2 ? "1 problem" : nil))
    }

    @Test func theSameCauseInAnotherLanguageIsOneProblem() {
        var run = StudioDebugRuns.failing
        var french = run.problems[0]
        french.id = "pr-french"
        french.target.locale = "fr-FR"
        run.problems.append(french)
        #expect(Self.strip(run).pill == "1 problem")
    }

    @Test(arguments: [(true, "Claude Design"), (false, "AppLocalizer’s starters")])
    func designingCountsTheDirections(design: Bool, designer: String) {
        let run = StudioDebugRuns.run(.design, design: design)
        let strip = Self.strip(run)
        #expect(AutopilotStripContent.designer(run) == designer)
        #expect(strip.text == "\(designer) is designing · 1 of 3 directions")
        #expect(strip.progress == 1.0 / 3.0)
    }

    @Test func localizingCountsTheCheckedScreenshots() {
        let strip = Self.strip(StudioDebugRuns.run(.localize))
        #expect(strip.text == "Localizing and checking · 60 of 120")
        #expect(strip.progress == 0.5)
    }

    @Test func progressNeverDropsBelowAHint() {
        var run = StudioDebugRuns.run(.capture)
        run.captures = []
        #expect(Self.strip(run).progress == 0.02)
    }

    // MARK: - Your turn

    @Test func pickingIsThePersonsTurn() {
        let strip = Self.strip(StudioDebugRuns.run(.pick))
        #expect(strip.kind == .yourTurn)
        #expect(strip.title == "Autopilot is waiting for you")
        #expect(strip.pill == "Your turn")
        #expect(strip.pillStyle == .machineTranslated)
        #expect(strip.text == "Pick the best captures for 5 screens. Claude Code’s picks are already selected.")
        #expect(strip.primary == .open)
        #expect(strip.progress == nil)
    }

    @Test(arguments: [(true, "Claude Design"), (false, "AppLocalizer’s starters")])
    func choosingNamesWhoMadeTheDirections(design: Bool, designer: String) {
        let strip = Self.strip(StudioDebugRuns.run(.choose, design: design))
        #expect(strip.kind == .yourTurn)
        #expect(strip.text == "Choose one of 3 directions from \(designer).")
    }

    // MARK: - Ready

    @Test func aReadySetWaitsInReviewAndPush() {
        let strip = Self.strip(StudioDebugRuns.run(.ready))
        #expect(strip.kind == .ready)
        #expect(strip.title == "New set ready")
        #expect(strip.pill == "Not pushed")
        #expect(strip.pillStyle == .accent)
        #expect(strip.text == "120 screenshots in Quiet Indigo · 1 caption shortened · waiting in Review & Push")
        #expect(strip.primary == .reviewPush)
        #expect(strip.secondary == .open)
    }

    @Test(arguments: [(0, "120 screenshots in Quiet Indigo · waiting in Review & Push"),
                      (2, "120 screenshots in Quiet Indigo · 2 captions shortened · waiting in Review & Push")])
    func shortenedCaptionsAreCounted(shortened: Int, text: String) {
        var run = StudioDebugRuns.run(.ready)
        run.shortenings = (0..<shortened).map { slot in
            AutopilotShortening(locale: "de-DE", slot: slot, before: "Long", after: "Short", client: "Claude Code")
        }
        #expect(Self.strip(run).text == text)
    }

    @Test func withoutAChosenDirectionTheCountStandsAlone() {
        var run = StudioDebugRuns.run(.ready)
        run.chosenDirectionID = nil
        run.shortenings = []
        #expect(Self.strip(run).text == "120 screenshots · waiting in Review & Push")
    }

    // MARK: - Helpers

    private static func strip(
        _ run: AutopilotRun?,
        assistant: String? = "Claude Code",
        project: DesignProject? = nil,
        hasNewSet: Bool = true
    ) -> AutopilotStripContent {
        AutopilotStripContent.make(run: run, appName: "Lumen Journal", assistant: assistant, designProject: project, hasNewSet: hasNewSet)
    }
}
#endif
