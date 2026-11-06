//
//  GuidedSetupTextTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The guided setup's words fit the app being set up: the designer it
/// really has, and ideas that aren't the sample app's (found running
/// Autopilot on MB Admin, which has no design project, and was offered
/// "Night sky with the moon").
@MainActor
@Suite("Guided setup · words that fit the app")
struct GuidedSetupTextTests {
    private var appID: StoreApp.ID { StudioTestFixtures.app.id }

    @Test func withoutADesignProjectAppLocalizerDesigns() async {
        let center = StudioTestFixtures.center(StudioDebugHeaderStyle.shotStyle)
        center.setDesignProject(nil, for: appID)
        let model = await StudioTestFixtures.screenshots(center: center)
        #expect(model.studio.guidedMakeIntro
            == "Choose any mix. \(model.studio.assistantTitle) captures the real app, and AppLocalizer designs, localizes and checks every image.")
    }

    @Test func withOneItNamesTheDesignerAndTheBrand() async {
        let center = StudioTestFixtures.center(StudioDebugHeaderStyle.shotStyle)
        center.setDesignProject(StudioDebugRuns.northpier, for: appID)
        let model = await StudioTestFixtures.screenshots(center: center)
        let studio = model.studio
        #expect(studio.guidedMakeIntro.contains("\(studio.shotStyleDesigner) designs it in \(StudioDebugRuns.northpier.displayName)"))
    }

    @Test func theQuickIdeasFitAnyApp() {
        let ideas = AutopilotArtworkDirection.additions.joined(separator: " ").lowercased()
        #expect(!ideas.contains("moon"))
        #expect(!ideas.contains("winter"))
        #expect(AutopilotArtworkDirection.additions.contains("Use the icon’s colors"))
    }
}
#endif
