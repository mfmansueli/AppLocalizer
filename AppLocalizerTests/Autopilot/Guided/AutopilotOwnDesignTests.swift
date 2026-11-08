//
//  AutopilotOwnDesignTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Without a design project, a guided plan has the assistant design the
/// screenshot looks from the app's own design (its docs, theme and icon)
/// instead of AppLocalizer's starters colored from the icon.
@MainActor
@Suite("Screenshot looks from the app's own design")
struct AutopilotOwnDesignTests {
    private let center = AutopilotTestFixtures.center()
    private let appID = AutopilotTestFixtures.appID

    // MARK: - The plan

    @Test func withoutTheChoiceThePlanUsesTheStarters() {
        let plan = AutopilotTestFixtures.smallPlan
        #expect(plan.assistantDesignsLooks == nil)
        #expect(plan.designKind(for: nil) == .none)
    }

    @Test func theAssistantDesignsWhenThePlanSaysSo() {
        var plan = AutopilotTestFixtures.smallPlan
        plan.assistantDesignsLooks = true
        #expect(plan.designKind(for: nil) == .claudeDesign)
        plan.assistantDesignsLooks = false
        #expect(plan.designKind(for: nil) == .none)
    }

    @Test func aDesignProjectAlwaysWins() {
        var plan = AutopilotTestFixtures.smallPlan
        plan.assistantDesignsLooks = false
        #expect(plan.designKind(for: StudioDebugRuns.northpier) == StudioDebugRuns.northpier.kind)
    }

    @Test func aGuidedPlanHasTheAssistantDesign() {
        var plan = AutopilotTestFixtures.singlePlan()
        GuidedDefaults.apply(to: &plan)
        #expect(plan.assistantDesignsLooks == true)
    }

    @Test func aPlanSavedBeforeTheChoiceStillLoads() throws {
        let data = try JSONEncoder().encode(AutopilotTestFixtures.smallPlan)
        let plan = try JSONDecoder().decode(AutopilotPlan.self, from: data)
        #expect(plan.assistantDesignsLooks == nil)
    }

    // MARK: - Start

    @Test func startWithoutAProjectHasTheAssistantDesign() throws {
        var plan = AutopilotTestFixtures.smallPlan
        plan.assistantDesignsLooks = true
        _ = center.prepare(appID: appID, versionString: "1.4", plan: plan)
        center.start(appID: appID)
        let run = try #require(center.run(for: appID))
        #expect(run.designKind == .claudeDesign)
        #expect(run.designName == nil)
        #expect(run.designsFromTheApp)
    }

    @Test func startWithAProjectDesignsInIt() throws {
        var plan = AutopilotTestFixtures.smallPlan
        plan.assistantDesignsLooks = true
        _ = center.prepare(appID: appID, versionString: "1.4", plan: plan)
        center.setDesignProject(StudioDebugRuns.northpier, for: appID)
        center.start(appID: appID)
        let run = try #require(center.run(for: appID))
        #expect(run.designName == "Northpier Brand")
        #expect(!run.designsFromTheApp)
    }

    @Test func startWithTheStartersTurnedOnStaysWithAppLocalizer() throws {
        var plan = AutopilotTestFixtures.smallPlan
        plan.assistantDesignsLooks = false
        _ = center.prepare(appID: appID, versionString: "1.4", plan: plan)
        center.start(appID: appID)
        let run = try #require(center.run(for: appID))
        #expect(run.designKind == .none)
        #expect(!run.designsFromTheApp)
    }

    // MARK: - Over MCP

    private static var ownDesignRun: AutopilotRun {
        var run = StudioDebugRuns.run(.design)
        run.plan.assistantDesignsLooks = true
        run.designKind = .claudeDesign
        run.designName = nil
        return run
    }

    @Test func theDesignStepSaysToDesignFromTheApp() {
        let how = AutopilotNextStep.designHow(plan: Self.ownDesignRun.plan, ownDesign: true)
        #expect(how.contains("the app's own design"))
        #expect(how.contains("aboutTheApp.look"))
        #expect(!how.contains("the person's design project"))
        #expect(AutopilotNextStep.designHow(plan: Self.ownDesignRun.plan).contains("the person's design project"))
    }

    @Test func theBriefSaysWhereTheDesignComesFrom() async throws {
        let fixtures = MCPAutopilotFixtures(Self.ownDesignRun)
        let brief = try await fixtures.call(GetDesignBriefTool(), ["run": "run-debug"]).result
        #expect(brief["designProject"] == nil)
        #expect(brief["designFrom"]?.stringValue?.contains("design docs, theme tokens") == true)
    }

    @Test func aBriefWithAProjectPointsAtIt() async throws {
        var run = Self.ownDesignRun
        run.designName = StudioDebugRuns.northpier.displayName
        let fixtures = MCPAutopilotFixtures(run, project: StudioDebugRuns.northpier)
        let brief = try await fixtures.call(GetDesignBriefTool(), ["run": "run-debug"]).result
        #expect(brief["designProject"] != nil)
        #expect(brief["designFrom"] == nil)
    }

    // MARK: - The guided plan

    @Test func thePlanSaysWhoDesigns() {
        var plan = AutopilotTestFixtures.smallPlan
        plan.assistantDesignsLooks = true
        #expect(GuidedStopsCard.designDetail(plan, client: "Claude Code").contains("Claude Code reads its design docs"))
        #expect(GuidedStopsCard.designSource(plan).contains("the app’s own"))
        plan.assistantDesignsLooks = false
        #expect(GuidedStopsCard.designDetail(plan, client: "Claude Code").contains("AppLocalizer’s starters"))
        #expect(GuidedStopsCard.designSource(plan).contains("AppLocalizer’s starters"))
    }
}
#endif
