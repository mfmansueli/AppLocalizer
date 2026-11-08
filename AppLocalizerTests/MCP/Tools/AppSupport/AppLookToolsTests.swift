//
//  AppLookToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The app's look and design language: report_app_support keeps it,
/// get_capture_plan asks for it when it's missing, and get_design_brief
/// hands it to the designers (or says to read it first).
@MainActor
@Suite("App look and design language")
struct AppLookToolsTests {
    private static let appID = DebugFixtures.AppID.lumen

    /// Lumen's look as a scan of its project would report it.
    static let look: JSONValue = [
        "whatItDoes": "A private journal: one prompt a day, a weekly view, search across years",
        "audience": "People who journal in the evening",
        "usageMoment": "At night, before bed, alone",
        "personality": "Calm and unhurried, like a lamp left on",
        "motifs": ["a crescent moon", "lamplight", "paper grain"],
        "avoid": ["notebooks and pens", "neon gradients"],
        "accentColor": "#5B5BD6",
        "themeColors": ["#F6F3EE", "#1E1B2E"],
        "fonts": ["New York Bold for titles", "SF Pro"],
        "supportsDarkMode": true,
        "iconDescription": "A white crescent on indigo, flat",
        "designSource": "DESIGN.md, Theme/Palette.swift",
        "headerTemplate": "night",
        "headerReason": "People write at night",
    ]

    private static func report(_ look: JSONValue, to center: AppSupportCenter) async throws {
        var storePage = DebugStorePageServices()
        storePage.appSupport = center
        let context = MCPToolContext(workspace: MCPTestFixtures.workspace(storePage: storePage), clientName: "Claude Code")
        _ = try await ReportAppSupportTool().call(
            MCPToolArguments(["appId": .string(appID), "languages": [["code": "en"]], "look": look]), in: context
        )
    }

    // MARK: - report_app_support

    @Test func theDesignLanguageIsKept() async throws {
        let center = AppSupportCenter()
        try await Self.report(Self.look, to: center)
        let look = try #require(center.profile(for: Self.appID)?.look)
        #expect(look.personality == "Calm and unhurried, like a lamp left on")
        #expect(look.motifs == ["a crescent moon", "lamplight", "paper grain"])
        #expect(look.avoid == ["notebooks and pens", "neon gradients"])
        #expect(look.designSource == "DESIGN.md, Theme/Palette.swift")
        #expect(look.hasDesignLanguage)
        #expect(look.isComplete)
        #expect(look.headerTemplate == .night)
    }

    @Test func blankListsAreLeftOut() {
        let look = AppLookProfile.mcp(["motifs": ["  ", ""], "avoid": [], "personality": " Quiet "])
        #expect(look?.motifs == nil)
        #expect(look?.avoid == nil)
        #expect(look?.personality == "Quiet")
    }

    @Test func aLookSavedBeforeTheDesignLanguageStillLoads() throws {
        let saved = ##"{"accentColor":"#5B5BD6","themeColors":["#F6F3EE"],"fonts":["SF Pro"],"audience":"Journalers"}"##
        let look = try JSONDecoder().decode(AppLookProfile.self, from: Data(saved.utf8))
        #expect(look.accentColor == "#5B5BD6")
        #expect(look.personality == nil && look.motifs == nil && look.avoid == nil)
        #expect(!look.hasDesignLanguage)
        #expect(!look.isComplete, "An older scan is read again")
    }

    @Test func theSchemaAsksForTheDesignLanguage() {
        let properties = AppLookProfile.mcpSchema["properties"]?.objectValue ?? [:]
        for key in ["personality", "motifs", "avoid", "designSource"] {
            #expect(properties[key] != nil, "\(key)")
        }
    }

    // MARK: - get_capture_plan

    @Test func withoutALookThePlanAsksForTheScanFirst() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.capture), appSupport: AppSupportCenter())
        let outcome = try await fixtures.call(GetCapturePlanTool(), ["run": "run-debug"])
        let appLook = try #require(outcome.result["appLook"])
        #expect(appLook["status"] == "missing")
        #expect(appLook["do"]?.stringValue?.contains("report_app_support") == true)
        #expect(appLook["do"]?.stringValue?.contains("avoid") == true)
    }

    @Test func anOlderScanIsAskedAgainWithWhatItHas() async throws {
        let center = AppSupportCenter()
        try await Self.report(["accentColor": "#5B5BD6", "audience": "Journalers", "whatItDoes": "A journal"], to: center)
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.capture), appSupport: center)
        let appLook = try #require(try await fixtures.call(GetCapturePlanTool(), ["run": "run-debug"]).result["appLook"])
        #expect(appLook["status"] == "incomplete")
        #expect(appLook["sofar"]?["accentColor"] == "#5B5BD6")
    }

    @Test func aKnownLookIsShownNotAskedFor() async throws {
        let center = AppSupportCenter()
        try await Self.report(Self.look, to: center)
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.capture), appSupport: center)
        let appLook = try #require(try await fixtures.call(GetCapturePlanTool(), ["run": "run-debug"]).result["appLook"])
        #expect(appLook["status"] == "known")
        #expect(appLook["look"]?["personality"] == "Calm and unhurried, like a lamp left on")
    }

    @Test func anAppLocalizerKeepingNoReportsSaysNothing() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.capture))
        let outcome = try await fixtures.call(GetCapturePlanTool(), ["run": "run-debug"])
        #expect(outcome.result["appLook"] == nil)
    }

    // MARK: - get_design_brief

    @Test func theBriefCarriesTheLook() async throws {
        let center = AppSupportCenter()
        try await Self.report(Self.look, to: center)
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.design), project: StudioDebugRuns.northpier, appSupport: center)
        let brief = try await fixtures.call(GetDesignBriefTool(), ["run": "run-debug"]).result
        let look = try #require(brief["aboutTheApp"]?["look"])
        #expect(look["personality"] == "Calm and unhurried, like a lamp left on")
        #expect(look["avoid"] == ["notebooks and pens", "neon gradients"])
        #expect(look["fonts"] == ["New York Bold for titles", "SF Pro"])
        #expect(look["supportsDarkMode"] == true)
        #expect(brief["lookMissing"] == nil)
        #expect(brief["aboutTheApp"]?["useIt"]?.stringValue?.contains("look.avoid") == true)
    }

    @Test func withoutALookTheBriefSaysToReadItFirst() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.design), project: StudioDebugRuns.northpier, appSupport: AppSupportCenter())
        let brief = try await fixtures.call(GetDesignBriefTool(), ["run": "run-debug"]).result
        #expect(brief["lookMissing"]?.stringValue?.contains("report_app_support") == true)
        #expect(brief["aboutTheApp"]?["look"] == nil)
    }

    // MARK: - The header and search prompts

    @Test func thePromptsCarryTheDesignLanguage() throws {
        let look = try #require(AppLookProfile.mcp(Self.look.objectValue))
        let run = StudioDebugHeaderStyle.headerOnly(.design, style: .free)
        let facts = ArtworkPromptFacts(look: look, ageRating: "18+", captions: [:])
        let text = ArtworkPromptBuilder(run: run, facts: facts, appName: "Lumen Journal").concepts().text
        #expect(text.contains("Calm and unhurried, like a lamp left on"))
        #expect(text.contains("“notebooks and pens”, “neon gradients”"))
        #expect(text.contains("“a crescent moon”, “lamplight”, “paper grain”"))
        #expect(text.contains("A private journal: one prompt a day"))
        #expect(text.contains("the project's own design docs (DESIGN.md, Theme/Palette.swift)"))
        #expect(text.contains("whatever the app's own age rating (18+)"))
        #expect(!text.contains("{{"))
    }

    @Test func withoutALookThePromptsSayUnknown() {
        let run = StudioDebugHeaderStyle.headerOnly(.design, style: .free)
        let values = ArtworkPromptValues(run: run, facts: ArtworkPromptFacts(), appName: "Lumen Journal").values
        #expect(values["brand_personality"] == "unknown")
        #expect(values["brand_avoid"] == "unknown")
        #expect(values["what_it_does"] == "unknown")
    }
}
#endif
