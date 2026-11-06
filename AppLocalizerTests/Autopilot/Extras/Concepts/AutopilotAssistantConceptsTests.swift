//
//  AutopilotAssistantConceptsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Header concepts without a design project: MB Admin's guided run chose
/// "Go freely" at Look, yet went straight to Choose with only
/// AppLocalizer's starters and no header to choose. A guided plan now has
/// the assistant design them, while Classic keeps the starters' header.
@MainActor
@Suite("Header concepts designed by the assistant")
struct AutopilotAssistantConceptsTests {
    private let center = AutopilotTestFixtures.center()
    private let context: AutopilotContext
    private let appID = StudioDebugRuns.appID

    init() {
        context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
    }

    private var run: AutopilotRun? { center.run(for: appID) }

    /// MB Admin's run at Pick: no design project, header and search art
    /// going freely, a guided plan or a Classic one.
    private static func picking(guided: Bool) -> AutopilotRun {
        var run = StudioDebugRuns.run(.pick, design: false)
        run.plan.alsoMakes.makesArtwork = true
        run.plan.alsoMakes.artworkStyle = .free
        run.plan.assistantDesignsArtwork = guided ? true : nil
        run.proposesConcepts = AutopilotRun.proposesConcepts(plan: run.plan, design: run.designKind) ? true : nil
        return run
    }

    @Test func aGuidedPlanHasTheAssistantDesignTheHeaders() {
        var plan = Self.picking(guided: false).plan
        #expect(!AutopilotRun.proposesConcepts(plan: plan, design: .none), "Classic: the starters draw the header")
        #expect(AutopilotRun.proposesConcepts(plan: plan, design: .claudeDesign))

        GuidedDefaults.apply(to: &plan)
        #expect(plan.assistantDesignsArtwork == true)
        #expect(AutopilotRun.proposesConcepts(plan: plan, design: .none))

        plan.alsoMakes.makesArtwork = false
        #expect(!AutopilotRun.proposesConcepts(plan: plan, design: .none), "No artwork, no concepts")
    }

    @Test func afterTheStartersItWaitsForTheAssistantsConcepts() async throws {
        center.install(Self.picking(guided: true))
        await center.usePicks(appID: appID, context: context)

        let run = try #require(run)
        #expect(run.stage == .design, "Not on to Choose without a header")
        #expect(run.directions.map(\.id) == ["starter-above", "starter-band", "starter-panorama"])
        #expect(run.usesConcepts)
        #expect(run.conceptsLeft == 3)
        #expect(run.designsArtwork)
        #expect(run.assistantHasWork, "AppLocalizer starts Claude Code for them")
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .design(remaining: 0))
        #expect(AutopilotNextStep.directionsHow(run: run).contains("Don't call propose_direction"))
    }

    @Test func classicStillGoesStraightToChoose() async throws {
        center.install(Self.picking(guided: false))
        await center.usePicks(appID: appID, context: context)

        let run = try #require(run)
        #expect(run.stage == .choose)
        #expect(!run.usesConcepts)
        #expect(!run.assistantHasWork)
    }

    @Test func thePlanSaysWhoDesignsWhat() {
        var plan = Self.picking(guided: true).plan
        plan.runChoice.makesScreenshots = true
        let design = GuidedPlanTimeline.rows(plan: plan, client: "Claude Code", design: .none, brand: nil).first { $0.kind == .design }
        #expect(design?.title.contains("3 headers") == true)
        #expect(design?.detail.hasPrefix("Screenshot looks from AppLocalizer’s starters, in the app icon’s colors; headers designed by Claude Design") == true)
    }
}
#endif
