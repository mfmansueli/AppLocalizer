//
//  AutopilotTurnTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// "Autopilot needs you": only the stops a run reached by itself, and the
/// center telling about each stage change.
@MainActor
@Suite("AutopilotTurn")
struct AutopilotTurnTests {
    @Test func theStopsARunReachesAreTurns() {
        #expect(AutopilotTurn.turn(from: .capture, to: .pick) == .pick)
        #expect(AutopilotTurn.turn(from: .design, to: .choose) == .choose)
        #expect(AutopilotTurn.turn(from: .localize, to: .watchPreview) == .review)
        #expect(AutopilotTurn.turn(from: .localize, to: .ready) == .review)
    }

    @Test func whatThePersonDidIsntNews() {
        #expect(AutopilotTurn.turn(from: .watchPreview, to: .ready) == nil, "Ready after Watch is their approval")
        #expect(AutopilotTurn.turn(from: .choose, to: .localize) == nil)
        #expect(AutopilotTurn.turn(from: .capture, to: .design) == nil)
        #expect(AutopilotTurn.turn(from: .choose, to: .choose) == nil)
        #expect(AutopilotTurn.turn(from: nil, to: .choose) == nil, "A run put in place, not reached")
    }

    @Test func theNotificationNamesTheAppAndTheRun() {
        #expect(AutopilotTurn.choose.title == "Autopilot needs you: choose the look")
        #expect(AutopilotTurn.review.body(appName: "Lumen Journal", startedAt: nil) == "Lumen Journal")
        #expect(AutopilotTurn.review.body(appName: "Lumen Journal", startedAt: .now).hasPrefix("Lumen Journal · the run started at "))
    }

    @Test func theCenterTellsEachStageChange() {
        let center = AutopilotTestFixtures.center()
        center.install(AutopilotTestFixtures.run(.design))
        var changes: [(AutopilotStage, AutopilotStage)] = []
        center.onStageChange = { run, old in changes.append((old, run.stage)) }

        center.update(AutopilotTestFixtures.appID) { $0.directions = [] }
        #expect(changes.isEmpty, "No stage change, nothing to tell")

        center.update(AutopilotTestFixtures.appID) { $0.stage = .choose }
        #expect(changes.count == 1)
        #expect(changes.first?.0 == .design)
        #expect(changes.first?.1 == .choose)
    }
}
#endif
