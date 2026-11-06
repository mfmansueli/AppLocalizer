//
//  GuidedLiveTimelineTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Making it's live steps and the stepper's ring: what's done, what
/// Autopilot works on now, what waits on the person and what's to come.
@MainActor
@Suite("GuidedLiveTimeline")
struct GuidedLiveTimelineTests {
    private typealias Fixtures = AutopilotTestFixtures
    private typealias State = GuidedLiveTimeline.State

    /// Capture, Pick, Design, Choose, Localize and Review: the small plan
    /// stops to pick and to choose.
    private static let rows = GuidedPlanTimeline.rows(plan: Fixtures.smallPlan, client: "Claude Code", design: .none, brand: nil)

    private func states(_ run: AutopilotRun) -> [State] {
        let states = GuidedLiveTimeline.states(of: Self.rows, run: run)
        return Self.rows.map { states[$0.kind] ?? .upcoming }
    }

    @Test func theRowsFollowTheRun() {
        #expect(Self.rows.map(\.kind) == [.capture, .pick, .design, .choose, .localize, .review])
    }

    @Test func capturingRunsTheFirstLine() {
        #expect(states(Fixtures.run(.waiting)) == [.running, .upcoming, .upcoming, .upcoming, .upcoming, .upcoming])
        #expect(states(Fixtures.run(.capture)) == [.running, .upcoming, .upcoming, .upcoming, .upcoming, .upcoming])
        #expect(GuidedLiveTimeline.isWorking(Fixtures.run(.capture)))
    }

    @Test func designingAfterThePicks() {
        #expect(states(Fixtures.run(.design)) == [.done, .done, .running, .upcoming, .upcoming, .upcoming])
    }

    @Test func thePersonsStopsWaitForThem() {
        #expect(states(Fixtures.run(.pick)) == [.done, .current, .upcoming, .upcoming, .upcoming, .upcoming])
        #expect(states(Fixtures.run(.choose)) == [.done, .done, .done, .current, .upcoming, .upcoming])
        #expect(!GuidedLiveTimeline.isWorking(Fixtures.run(.choose)))
    }

    @Test func localizingAfterChoose() {
        #expect(states(Fixtures.run(.localize)) == [.done, .done, .done, .done, .running, .upcoming])
    }

    @Test func readyWaitsForTheReviewThenIsAllDone() {
        var run = Fixtures.run(.ready)
        #expect(states(run) == [.done, .done, .done, .done, .done, .current])
        run.guidedReview = AutopilotGuidedReview(pushedAt: Fixtures.now)
        #expect(states(run) == Array(repeating: .done, count: 6))
    }

    @Test func aProblemOnlyThePersonCanSolvePausesTheRing() {
        var run = Fixtures.run(.capture)
        run.problems = [Fixtures.problem(Fixtures.target("today"))]
        #expect(!GuidedLiveTimeline.isWorking(run))
        #expect(states(run).first == .current)
    }

    @Test func aMissingLinePassesToTheNextOne() {
        // Nothing to capture (header art that shows no app): starting goes
        // to the design line.
        let rows = Self.rows.filter { $0.kind != .capture && $0.kind != .pick }
        let states = GuidedLiveTimeline.states(of: rows, run: Fixtures.run(.waiting))
        #expect(states[.design] == .running)
        #expect(states[.choose] == .upcoming)
    }

    @Test func nothingRunsWhilePlanned() {
        #expect(states(Fixtures.run(.plan)) == Array(repeating: .upcoming, count: 6))
        #expect(!GuidedLiveTimeline.isWorking(Fixtures.run(.plan)))
    }
}
#endif
