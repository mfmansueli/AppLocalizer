//
//  StarterDirectionMakerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Design without a design project: AppLocalizer's three starters, in the
/// app icon's colors when it has one.
@MainActor
@Suite("Starter directions")
struct StarterDirectionMakerTests {
    private let run = AutopilotTestFixtures.run(.design)

    private func maker(icon: AppIcon?) -> StarterDirectionMaker {
        var app = AutopilotTestFixtures.app
        app.icon = icon
        let context = AutopilotContext(app: app, services: FakeScreenshotsServices(), primaryLocale: .englishUS)
        return StarterDirectionMaker(context: context, now: { AutopilotTestFixtures.now })
    }

    @Test func theStartersTakeTheIconsColors() async {
        let directions = await maker(icon: AutopilotTestFixtures.app.icon).directions(for: run)
        let palette = IconPalette(light: "#7C86FF", dark: "#3A2FB8")

        #expect(directions.map(\.id) == ["starter-above", "starter-band", "starter-panorama"])
        #expect(directions.map(\.name) == TemplateStarter.simple.map(\.title))
        #expect(directions.allSatisfy { $0.source == .none && $0.client == nil && $0.sourceTitle == "Starter" })
        #expect(directions.allSatisfy { $0.template.slots.count == 2 && $0.receivedAt == AutopilotTestFixtures.now })
        #expect(directions[0].rationale == "AppLocalizer’s starter, in the colors of Lumen Journal’s app icon.")
        #expect(directions[0].template.background.stops == palette.gradient)
        let band = directions[1].template
        #expect(band.background.stops == [palette.darkest])
        #expect(band.caption.band.color == palette.darkest)
        #expect(directions[2].template.background.stops == palette.panorama)
        #expect(directions[2].template.caption.ink == palette.darkest)
    }

    @Test func withoutAnIconTheStartersKeepTheirOwnColors() async {
        let directions = await maker(icon: nil).directions(for: run)
        #expect(directions.allSatisfy { $0.rationale == "AppLocalizer’s starter, in its own colors." })
        let plain = ScreenshotTemplate.starter(.band, id: AutopilotTestFixtures.appID, title: "Lumen Journal", slotCount: 2)
        #expect(directions[1].template == plain)
    }

    // MARK: - Screenshot style

    @Test func fromTemplatesEachPickedTemplateIsADirection() async {
        var run = run
        run.plan.screenshotStyle = .templates
        run.plan.screenshotTemplates = [TemplateStarter.cinema.title, "editorial", "Not a template"]
        let directions = await maker(icon: AutopilotTestFixtures.app.icon).directions(for: run)
        #expect(directions.map(\.id) == ["starter-cinema", "starter-editorial"], "Matched by title, in the order picked")
        #expect(directions.map(\.name) == ["\(TemplateStarter.cinema.title) · for Lumen Journal", "\(TemplateStarter.editorial.title) · for Lumen Journal"])
        #expect(directions[0].rationale == "From the \(TemplateStarter.cinema.title) template, in the app icon’s colors.")

        let plain = await maker(icon: nil).directions(for: run)
        #expect(plain[0].rationale == "From the \(TemplateStarter.cinema.title) template, in its own colors.")
    }

    @Test func keepingTheTemplateIsTheOnlyDirection() async throws {
        let services = DebugScreenshotsServices()
        let context = AutopilotContext(app: AutopilotTestFixtures.app, services: services, primaryLocale: .englishUS)
        let maker = StarterDirectionMaker(context: context, now: { AutopilotTestFixtures.now })
        let kept = try #require(await maker.keptDirection(for: run))
        #expect(kept.id.hasPrefix("kept-v"))
        #expect(kept.name.hasPrefix("Template v"))
        #expect(kept.rationale == "Your current template, with the new captures and captions.")

        let none = StarterDirectionMaker(
            context: AutopilotContext(app: AutopilotTestFixtures.app, services: FakeScreenshotsServices(), primaryLocale: .englishUS),
            now: { AutopilotTestFixtures.now }
        )
        #expect(await none.keptDirection(for: run) == nil, "A set without a template keeps nothing")
    }

    @Test func theScreenshotStylesDirectionCount() {
        var run = run
        #expect(run.expectedDirections == 3)
        run.plan.screenshotStyle = .templates
        run.plan.screenshotTemplates = ["Cinema", "Poster"]
        #expect(run.expectedDirections == 2)
        run.plan.screenshotTemplates = []
        #expect(run.expectedDirections == 1)
        run.plan.screenshotStyle = .keep
        #expect(run.expectedDirections == 1)
        #expect(!run.choosesDirection, "The kept template is the only one")
        #expect(AutopilotShotStyle.directionName(template: "Cinema", app: "Lumen") == "Cinema · for Lumen")
    }
}
#endif
