//
//  MacSimulatorsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Checking this Mac's simulators through the helper, and the fix: install
/// the platform's simulator, then make the simulator.
@MainActor
@Suite("Mac simulators")
struct MacSimulatorsTests {
    private let helper = URL(filePath: "/tmp/Start Claude Code.zsh")

    private static func lines(newRuntime: Bool = false, duo: Bool = false) -> [String] {
        [DebugSimulators.json(DebugSimulators.Mac(hasNewRuntime: newRuntime, hasDuo: duo))]
    }

    @Test func theCheckReadsTheList() async {
        let runner = FakeUnixScriptRunner()
        runner.answers["simulators"] = [Self.lines()]
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        #expect(simulators.status(for: .iPhone) == nil, "Not checked yet")
        await simulators.check()

        #expect(simulators.status(for: .iPhone)?.canCapture == true)
        #expect(simulators.missing(in: [.iPhone, .iPhoneDuo, .iPad]) == [.iPhoneDuo])
        #expect(simulators.message == nil)
        #expect(runner.recordedArguments == [["simulators"]])
    }

    @Test func withoutTheHelperItSaysToInstallIt() async {
        let runner = FakeUnixScriptRunner()
        runner.helperExists = false
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        await simulators.check()
        #expect(simulators.state == .noHelper)
        #expect(simulators.message?.contains("Install the helper") == true)
        #expect(simulators.missing(in: [.iPhoneDuo]).isEmpty, "Nothing is known to be missing")
    }

    @Test func anOlderHelperIsToBeSavedAgain() async {
        let runner = FakeUnixScriptRunner()
        runner.exitStatus = 64
        runner.losesExitLine = true
        runner.errorOutput = "Usage: Start Claude Code.zsh check | run <folder> -- <claude arguments…>"
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        await simulators.check()
        #expect(simulators.state == .oldHelper)
        #expect(simulators.message?.contains("Save the helper again") == true)
    }

    @Test func installingDownloadsThePlatformThenMakesTheSimulator() async {
        let runner = FakeUnixScriptRunner()
        runner.answers = [
            "simulators": [Self.lines(), Self.lines(newRuntime: true), Self.lines(newRuntime: true, duo: true)],
            "install-platform": [DebugSimulators.downloadLines],
            "create-simulator": [["6F0D2C5E-0A3B-4C1D-9E8F-1A2B3C4D5E6F"]],
        ]
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        await simulators.check()
        await simulators.install(for: .iPhoneDuo)

        #expect(runner.recordedArguments == [
            ["simulators"],
            ["install-platform", "iOS"],
            ["simulators"],
            ["create-simulator", "iPhone Duo", "com.apple.CoreSimulator.SimDeviceType.iPhone-Duo", "com.apple.CoreSimulator.SimRuntime.iOS-27-2"],
            ["simulators"],
        ])
        #expect(simulators.status(for: .iPhoneDuo) == .ready(simulator: "iPhone Duo", runtime: "iOS 27.2"))
        #expect(simulators.working == nil)
        #expect(simulators.failure == nil)
    }

    @Test func aFailedDownloadSaysWhyAndMakesNothing() async {
        let runner = FakeUnixScriptRunner()
        runner.answers = [
            "simulators": [Self.lines()],
            "install-platform": [["Downloading iOS 27.2 Simulator (24C61): 3.0%", "Error: The network connection was lost."]],
        ]
        runner.statuses["install-platform"] = 70
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        await simulators.check()
        await simulators.install(for: .iPhoneDuo)

        #expect(simulators.failure == "Error: The network connection was lost.")
        #expect(!runner.recordedArguments.contains { $0.first == "create-simulator" })
        #expect(simulators.status(for: .iPhoneDuo)?.canCapture == false)
    }

    /// A run already capturing gets its device's problem when it's looked
    /// at again, once; a run at Plan gets none.
    @Test func aRunCapturingGetsTheDeviceThisMacCantRunOnce() async throws {
        let runner = FakeUnixScriptRunner()
        runner.answers["simulators"] = [Self.lines()]
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        await simulators.check()
        var run = AutopilotTestFixtures.run(.capture)
        run.plan.setPlans(.iPhoneDuo, true)
        let center = AutopilotCenter(runs: [run.appID: run])

        #expect(center.reportMissingSimulators(appID: run.appID, simulators: simulators) == [.iPhoneDuo])
        #expect(center.reportMissingSimulators(appID: run.appID, simulators: simulators).isEmpty, "Its problem is open already")
        let reported = try #require(center.run(for: run.appID))
        let problem = try #require(reported.openProblems.first)
        #expect(reported.openProblems.count == 1)
        #expect(problem.isDeviceWide)
        #expect(problem.target.displayType == .iPhoneDuo)
        #expect(problem.proposedFix == "Install the iOS simulator (xcodebuild -downloadPlatform iOS).")
        #expect(!reported.nextTargets.contains { $0.displayType == .iPhoneDuo })
        #expect(reported.assistantHasWork, "The other devices go on")

        var planned = AutopilotTestFixtures.run(.plan)
        planned.plan.setPlans(.iPhoneDuo, true)
        #expect(AutopilotCenter(runs: [planned.appID: planned]).reportMissingSimulators(appID: planned.appID, simulators: simulators).isEmpty)
    }

    @Test func aReadyDeviceInstallsNothing() async {
        let runner = FakeUnixScriptRunner()
        runner.answers["simulators"] = [Self.lines()]
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        await simulators.check()
        await simulators.install(for: .iPhone)
        await simulators.make(for: .iPhone)
        #expect(runner.recordedArguments == [["simulators"]])
    }
}
#endif
