//
//  AutopilotGuidedStripTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The guided front's strip on the Screenshots page: Start…, the run's
/// progress while it goes on its own, "Your turn" at the stops, Sent once
/// pushed.
@MainActor
@Suite("AutopilotStripContent · guided")
struct AutopilotGuidedStripTests {
    private static func strip(_ run: AutopilotRun?, assistant: String? = "Claude Code") -> AutopilotStripContent {
        AutopilotStripContent.guided(
            run: run, appName: "Lumen Journal", assistant: assistant, designProject: StudioDebugRuns.northpier, hasNewSet: true,
            now: StudioTestFixtures.now
        )
    }

    @Test func aNewRunStartsInThreeSteps() {
        let strip = Self.strip(nil)
        #expect(strip.title == "Autopilot")
        #expect(strip.pill == "New")
        #expect(strip.primaryTitle == "Start…")
        #expect(strip.primary == .runAutopilot)
        #expect(strip.text.hasPrefix("Make new screenshots, an App Preview and header artwork in 3 short steps."))
    }

    @Test func withoutAnAssistantItStillOffersTheSetup() {
        #expect(Self.strip(nil, assistant: nil).kind == .needsAssistant)
    }

    @Test func aPlanContinuesTheSetup() {
        let strip = Self.strip(StudioDebugGuided.planned())
        #expect(strip.primaryTitle == "Continue Setup…")
        #expect(strip.primary == .open)
        #expect(strip.pill == nil)
    }

    @Test func aRunningRunShowsItsProgress() throws {
        let strip = Self.strip(StudioDebugGuided.designing(arrived: 2))
        #expect(strip.kind == .running)
        #expect(strip.title == "Autopilot is running")
        #expect(strip.text.hasPrefix("Designing in Northpier Brand · "))
        #expect(strip.text.hasSuffix("%. You’ll be notified when it needs you."))
        let progress = try #require(strip.progress)
        #expect(progress > 0 && progress < 1)
        #expect(strip.primary == .open)
    }

    /// MB Admin's strip said "Autopilot is running" after AppLocalizer
    /// was reopened, while nothing ran.
    @Test func aPausedOrStoppedRunSaysSo() {
        let run = StudioDebugGuided.designing(arrived: 2)
        let paused = AutopilotStripContent.guided(
            run: run, appName: "Lumen Journal", assistant: "Claude Code", designProject: StudioDebugRuns.northpier, hasNewSet: true,
            stall: .notRunning, now: StudioTestFixtures.now
        )
        #expect(paused.title == "Autopilot is paused")
        #expect(paused.text == AutopilotStall.notRunning.headline(of: run, now: StudioTestFixtures.now))
        #expect(paused.primaryTitle == "Continue…")
        #expect(paused.primary == .open)

        let stopped = AutopilotStripContent.guided(
            run: run, appName: "Lumen Journal", assistant: "Claude Code", designProject: StudioDebugRuns.northpier, hasNewSet: true,
            stall: .ended(lastWords: nil), now: StudioTestFixtures.now
        )
        #expect(stopped.title == "Autopilot stopped")
        #expect(stopped.text.hasPrefix("Claude Code stopped with "))

        let handedBack = AutopilotStripContent.guided(
            run: run, appName: "Lumen Journal", assistant: "Claude Code", designProject: StudioDebugRuns.northpier, hasNewSet: true,
            stall: .handedBack, now: StudioTestFixtures.now
        )
        #expect(handedBack.title == "Autopilot is running", "Its turn again isn't a stop")
    }

    @Test func theStopsAreThePersonsTurn() {
        let choose = Self.strip(StudioDebugGuided.choosing)
        #expect(choose.kind == .yourTurn)
        #expect(choose.title == "Autopilot needs you")
        #expect(choose.pill == "Your turn")
        #expect(choose.text == "Choose the look: the screenshot looks and headers are ready.")
        #expect(choose.primaryTitle == "Choose the Look…")

        let review = Self.strip(StudioDebugGuided.ready(approved: []))
        #expect(review.kind == .yourTurn)
        #expect(review.text == "Everything is made and checked. Review it, then push.")
        #expect(review.primaryTitle == "Review…")

        #expect(Self.strip(StudioDebugRuns.run(.pick)).primaryTitle == "Pick the Captures…")
    }

    @Test func aPushedRunIsSent() {
        let strip = Self.strip(StudioDebugGuided.ready(approved: GuidedReviewPart.allCases, pushed: true))
        #expect(strip.title == "Sent to the App Store")
        #expect(strip.pill == "Pushed")
        #expect(strip.primaryTitle == "New Run…")
        #expect(strip.primary == .runAutopilot)
        #expect(strip.secondary == .open)
    }
}
#endif
