//
//  GuidedLookNameTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Review's look line names the app once, in its header: Bruma's said it
/// twice more.
@Suite("Guided look name")
struct GuidedLookNameTests {
    private let app = "Bruma – Gay Dating Nearby"

    @Test func aDirectionMadeForTheAppLosesItsName() {
        let name = AutopilotShotStyle.directionName(template: "Social Proof", app: app)
        #expect(GuidedLookName.short(name, app: app) == "Social Proof")
    }

    @Test func aStarterTemplateLosesItsName() {
        let template = ScreenshotTemplate.starter(.above, id: "1", title: app)
        #expect(GuidedLookName.short(template.name, app: app) == TemplateStarter.above.title)
    }

    @Test func otherNamesStayAsTheyAre() {
        #expect(GuidedLookName.short("Night Ink", app: app) == "Night Ink")
        #expect(GuidedLookName.short("\(app) · ", app: app) == "\(app) · ")
        #expect(GuidedLookName.short("Night Ink", app: "") == "Night Ink")
    }
}
#endif
