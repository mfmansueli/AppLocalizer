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
        #expect(directions.map(\.name) == TemplateStarter.allCases.map(\.title))
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
}
#endif
