//
//  AutopilotHeaderStyleTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The plan's Header style and Screenshot style: up to three picks in
/// order (a fourth replaces the last), the recommended template first,
/// Claude Code's recommendation from its scan, else AppLocalizer's guess.
@MainActor
@Suite("Header style and Screenshot style")
struct AutopilotHeaderStyleTests {
    @Test func theRecommendedTemplateComesFirst() {
        #expect(AutopilotHeaderTemplate.defaultPicks(recommended: .window) == [.window, .night, .land])
        #expect(AutopilotHeaderTemplate.defaultPicks(recommended: .night) == [.night, .land, .window])
    }

    @Test func aFourthPickReplacesTheLast() {
        let picks: [AutopilotHeaderTemplate] = [.night, .land, .window]
        #expect(AutopilotHeaderTemplate.toggling(.hero, in: picks) == [.night, .land, .hero])
        #expect(AutopilotHeaderTemplate.toggling(.land, in: picks) == [.night, .window], "Picked again takes it out")
        #expect(AutopilotHeaderTemplate.toggling(.hero, in: []) == [.hero])
        #expect(AutopilotShotStyle.toggling("Poster", in: ["Cinema", "Editorial", "Bold Stack"]) == ["Cinema", "Editorial", "Poster"])
        #expect(AutopilotShotStyle.toggling("Cinema", in: ["Cinema"]).isEmpty)
    }

    @Test func theGuessFollowsTheCategories() {
        #expect(AutopilotHeaderTemplate.guess(categories: ["Travel"]) == .window)
        #expect(AutopilotHeaderTemplate.guess(categories: ["Health & Fitness"]) == .land)
        #expect(AutopilotHeaderTemplate.guess(categories: ["Finance"]) == .hero)
        #expect(AutopilotHeaderTemplate.guess(categories: []) == .night)
        let guess = AutopilotHeaderRecommendation.guess(categories: ["Lifestyle"], client: "Claude Code")
        #expect(!guess.isFromScan)
        let text = "Recommended for Lumen: Day to Night. It suits Lifestyle apps. Claude Code gives its own reason once it has read the project."
        #expect(guess.text(appName: "Lumen") == text)
    }

    @Test func claudeCodesScanRecommendsOne() throws {
        let look = try #require(AppLookProfile.mcp([
            "accentColor": "#6E66E8", "themeColors": ["#2B2668", " "], "supportsDarkMode": true, "whatItDoes": "A journal for the evening.",
            "headerTemplate": "Window", "headerReason": "People write in Lumen at night, by a window.",
        ]))
        #expect(look.themeColors == ["#2B2668"], "Empty values are left out")
        #expect(look.whatItDoes == "A journal for the evening.")
        let recommendation = try #require(look.headerRecommendation)
        #expect(recommendation.template == .window)
        #expect(recommendation.isFromScan)
        #expect(recommendation.text(appName: "Lumen") == "Recommended for Lumen: Window View. People write in Lumen at night, by a window.")
        #expect(AppLookProfile.mcp(["fonts": []]) == nil, "A look that says nothing")
    }

    @Test func goingFreelyMakesThreeConcepts() {
        var extras = AutopilotExtras(makesArtwork: true, artworkSize: .headerAndSearch)
        #expect(extras.artworkStyle == .templates, "Templates unless the person goes freely")
        extras.headerTemplates = [.night]
        #expect(extras.conceptCount == 1)
        extras.artworkStyle = .free
        #expect(extras.conceptCount == 3)
    }

    @Test func plansFromBeforeKeepTheirOwnStyle() throws {
        var plan = AutopilotTestFixtures.smallPlan
        plan.alsoMakes = AutopilotExtras(makesArtwork: true, artworkSize: .headerAndSearch)
        let decoded = try JSONDecoder().decode(AutopilotPlan.self, from: JSONEncoder().encode(plan))
        #expect(decoded.alsoMakes.artworkStyle == .templates)
        #expect(decoded.alsoMakes.headerTemplates.isEmpty)
        #expect(decoded.screenshotStyle == .free)
        #expect(decoded.screenshotTemplates.isEmpty)
    }
}
#endif
