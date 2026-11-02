//
//  AutopilotDirectionCardTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Design's three cards: only the next direction spins, and only while
/// someone works on the run; it counts from the brief's reading or the
/// last direction, since the person handed the design over.
@MainActor
@Suite("Autopilot direction cards")
struct AutopilotDirectionCardTests {
    @Test func theNextDirectionDesignsAndTheOneAfterIsUpNext() {
        let run = StudioDebugRuns.run(.design)
        let first = run.directions[0]
        #expect(AutopilotDirectionCard.cards(of: run, isWorking: true) == [.arrived(first), .designing(since: first.receivedAt), .upNext])
    }

    @Test func nothingSpinsWhileNobodyWorks() {
        let run = StudioDebugRuns.run(.design)
        #expect(AutopilotDirectionCard.cards(of: run, isWorking: false) == [.arrived(run.directions[0]), .waiting, .waiting])
    }

    @Test func itDesignsSinceTheBriefWasReadAfterTheHandOver() throws {
        var run = StudioDebugRuns.run(.design)
        let directions = run.directions
        run.directions = []
        let handedOver = try #require(run.lastNewsAt).addingTimeInterval(3600)
        run.handedBackAt = handedOver
        run.briefReadAt = handedOver.addingTimeInterval(-600)
        #expect(AutopilotDirectionCard.cards(of: run, isWorking: true) == [.designing(since: nil), .upNext, .upNext], "Read in an earlier round")

        run.briefReadAt = handedOver.addingTimeInterval(30)
        #expect(AutopilotDirectionCard.cards(of: run, isWorking: true).first == .designing(since: handedOver.addingTimeInterval(30)))

        var arrived = directions[0]
        arrived.receivedAt = handedOver.addingTimeInterval(300)
        run.directions = [arrived]
        #expect(AutopilotDirectionCard.cards(of: run, isWorking: true) == [.arrived(arrived), .designing(since: arrived.receivedAt), .upNext])
    }

    @Test func revisingKeepsEveryDirectionShown() {
        var run = StudioDebugRuns.run(.choose)
        run.stage = .design
        run.revision = AutopilotRevisionRequest(note: "Bigger headline", askedAt: AutopilotTestFixtures.now)
        #expect(AutopilotDirectionCard.cards(of: run, isWorking: true) == run.directions.map(AutopilotDirectionCard.arrived))
    }
}
#endif
