//
//  ScreenshotStudioPlanProposalsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What the assistant sent for the next plan, as the Studio shows it: the
/// strip's line between runs, the screens under each device, Accept and
/// Reject, and Remove on the commands and notes fixes added.
@MainActor
@Suite("ScreenshotStudioModel · Plan proposals")
struct ScreenshotStudioPlanProposalsTests {
    private var appID: StoreApp.ID { StudioTestFixtures.app.id }

    private static func change(_ id: String, sampleData: String? = nil, commands: [String]? = nil) -> AutopilotPlanChange {
        AutopilotPlanChange(id: id, client: "Claude Code", receivedAt: StudioTestFixtures.now, sampleData: sampleData, setupCommands: commands)
    }

    private static func screens(_ names: [String]) -> [AutopilotScreenSuggestion] {
        names.map { AutopilotScreenSuggestion(id: "s-\($0)", name: $0, reason: "New in 1.1.", steps: "tab “\($0)”", caption: "") }
    }

    @Test func theStripSaysWhatWaitsForTheNextRun() async throws {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.ready))
        let model = await StudioTestFixtures.screenshots(center: center)
        let before = model.studio.guidedStrip(assistant: "Claude Code").text
        #expect(model.studio.planProposalsLine == nil)

        center.queuePlanChange(Self.change("pc-1", sampleData: "-ui-sample"), appID: appID)
        try center.queueScreenSuggestions(Self.screens(["My Phrases", "Streak"]), on: .iPhone, client: "Claude Code", appID: appID)
        let line = "For the next run: 1 plan change and 2 suggested screens from Claude Code."
        #expect(model.studio.planProposalsLine == line)
        #expect(model.studio.guidedStrip(assistant: "Claude Code").text == before + " " + line)
        #expect(model.studio.queuedScreens(on: .iPhone).first?.items.count == 2)
        #expect(model.studio.queuedScreens(on: .watch).isEmpty)
    }

    @Test func theStripLeavesItOutWhileARunGoes() async {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.capture))
        let model = await StudioTestFixtures.screenshots(center: center)
        let before = model.studio.guidedStrip(assistant: "Claude Code").text
        center.queuePlanChange(Self.change("pc-1", sampleData: "-ui-sample"), appID: appID)
        #expect(model.studio.guidedStrip(assistant: "Claude Code").text == before)
    }

    @Test func acceptAndRejectAtThePlan() async throws {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.plan))
        let model = await StudioTestFixtures.screenshots(center: center)
        center.queuePlanChange(Self.change("pc-1", sampleData: "-ui-sample-phrases"), appID: appID)
        center.queuePlanChange(Self.change("pc-2", commands: ["xcrun simctl privacy booted grant photos com.northpier.lumen"]), appID: appID)

        model.studio.acceptPlanChange("pc-1")
        model.studio.rejectPlanChange("pc-2")
        let plan = try #require(center.run(for: appID)?.plan)
        #expect(plan.simulator.sampleDataSteps == "-ui-sample-phrases")
        #expect(plan.simulator.extraCommands.isEmpty)
        #expect(model.studio.planProposals.isEmpty)
    }

    /// Alba's plan kept refused commands and done instructions forever:
    /// each now has Remove at the plan.
    @Test func theCommandsAndNotesFixesAddedCanBeRemoved() async throws {
        var run = StudioDebugRuns.run(.plan)
        run.plan.simulator.extraCommands = ["xcrun simctl privacy booted grant photos com.northpier.lumen", "xcrun simctl ui booted increase_contrast enabled"]
        run.plan.simulator.fixNotes = ["Install the iOS 27.1+ simulator runtime"]
        let center = StudioTestFixtures.center(run)
        let model = await StudioTestFixtures.screenshots(center: center)

        model.studio.removeFixCommand("xcrun simctl privacy booted grant photos com.northpier.lumen")
        model.studio.removeFixNote("Install the iOS 27.1+ simulator runtime")
        let simulator = try #require(center.run(for: appID)?.plan.simulator)
        #expect(simulator.extraCommands == ["xcrun simctl ui booted increase_contrast enabled"])
        #expect(simulator.fixNotes.isEmpty)
    }

    /// Kept between launches with the runs.
    @Test func whatWaitsIsSavedWithTheRuns() throws {
        let archive = AutopilotArchive(planProposals: [
            appID: AutopilotPlanProposals(
                screens: [
                    AutopilotScreenSuggestions(client: "Claude Code", items: Self.screens(["My Phrases"]), receivedAt: StudioTestFixtures.now, id: "ps-1"),
                ],
                changes: [Self.change("pc-1", sampleData: "-ui-sample")]
            ),
        ])
        let read = try JSONDecoder().decode(AutopilotArchive.self, from: JSONEncoder().encode(archive))
        #expect(read == archive)
        let before = try JSONDecoder().decode(AutopilotArchive.self, from: Data(#"{"runs":{},"designProjects":{}}"#.utf8))
        #expect(before.planProposals == nil)
    }
}
#endif
