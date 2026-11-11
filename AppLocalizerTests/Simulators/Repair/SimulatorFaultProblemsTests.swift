//
//  SimulatorFaultProblemsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Which of a run's open problems AppLocalizer repairs itself.
@MainActor
@Suite("Simulator fault problems")
struct SimulatorFaultProblemsTests {
    private static let audio = "won't boot on this Mac right now: SimAudioProcessorServices failed to create an audio route descriptor"

    private static func problem(_ what: String, deviceWide: Bool = true, index: Int = 0) throws -> AutopilotProblem {
        let run = AutopilotTestFixtures.run(.capture)
        var problem = try AutopilotTestFixtures.problem(#require(run.plan.targets.dropFirst(index).first), fix: "sudo killall coreaudiod")
        problem.id = "pr-\(index)"
        problem.what = what
        problem.affectsDevice = deviceWide ? true : nil
        return problem
    }

    @Test func deviceWideProblemsOverAKnownFaultAreRepaired() throws {
        let found = try ScreenshotStudioModel.simulatorFaultProblems(in: [
            Self.problem("iPhone 17 Pro Max " + Self.audio),
            Self.problem("The photo picker covered the entry.", deviceWide: false, index: 1),
            Self.problem("iPad Pro 13-inch: Unable to boot device in current state: Shutdown", index: 2),
        ])
        #expect(found?.fault == .audioService, "The audio repair covers the simulator service too")
        #expect(found?.problems.map(\.id) == ["pr-0", "pr-2"])
    }

    @Test func aStuckServiceAloneNeedsNoPassword() throws {
        let found = try ScreenshotStudioModel.simulatorFaultProblems(in: [Self.problem("Unable to boot device in current state: Shutdown")])
        #expect(found?.fault == .simulatorService)
    }

    @Test func aScreensProblemOrTheProjectsIsNotRepaired() throws {
        // One screen that mentions it isn't the whole device.
        #expect(try ScreenshotStudioModel.simulatorFaultProblems(in: [Self.problem(Self.audio, deviceWide: false)]) == nil)
        var projects = try Self.problem("The UI tests don’t build for this device: failed to boot the test runner")
        projects.changesProject = true
        #expect(ScreenshotStudioModel.simulatorFaultProblems(in: [projects]) == nil)
        #expect(ScreenshotStudioModel.simulatorFaultProblems(in: []) == nil)
    }
}
#endif
