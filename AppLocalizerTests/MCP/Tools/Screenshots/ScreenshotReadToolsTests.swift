//
//  ScreenshotReadToolsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// `get_screenshot_context`, `list_captures`, `get_template` and
/// `get_captions` on Lumen's sample screenshots.
@MainActor
@Suite("Screenshot read tools")
struct ScreenshotReadToolsTests {
    private let fixture = MCPScreenshotsFixtures.workspace()

    private func call(_ tool: some MCPTool, _ arguments: [String: JSONValue] = [:]) async throws -> MCPToolOutcome {
        try await MCPScreenshotsFixtures.call(tool, arguments, in: fixture.0)
    }

    @Test func theContextNamesSlotsFromOneAndThePrimaryCaptions() async throws {
        let outcome = try await call(GetScreenshotContextTool())
        let result = outcome.result
        #expect(result["primaryLocale"] == "en-US")
        #expect(result["templateVersion"] == 4)
        #expect(result["hasCaptures"] == true)
        #expect(result["displayTypes"]?.arrayValue?.compactMap { $0["displayType"]?.stringValue } == ["iphone", "iphone_duo", "ipad"])
        #expect(result["displayTypes"]?.arrayValue?.first?["portraitPixelSize"] == ["width": 1320, "height": 2868])
        let slots = try #require(result["slots"]?.arrayValue)
        #expect(slots.count == 5)
        #expect(slots[0] == [
            "slot": 1, "name": "Today", "primaryHeadline": "Write a little every day",
            "primarySubhead": "Gentle prompts that fit your mood",
        ])
        #expect(slots[2]["name"] == "Search")
        let locales = try #require(result["localesInScope"]?.arrayValue)
        #expect(locales.count == ScreenshotsSampleData.scope.count)
        #expect(locales.first == ["code": "en-US", "name": "English (U.S.)"])
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Screenshots", outcome: .read)])
    }

    @Test func anUnknownAppIsNotFound() async {
        await #expect(throws: MCPToolError.self) { try await call(GetScreenshotContextTool(), ["appId": "Nope"]) }
    }

    @Test func capturesSayWhetherTheyShowTheLocalesOwnInterface() async throws {
        let german = try await call(ListCapturesTool(), ["locale": "de-DE", "displayType": "iphone"])
        let captures = try #require(german.result["captures"]?.arrayValue)
        #expect(captures.count == 5)
        #expect(captures.allSatisfy { $0["localizedUI"] == true && $0["locale"] == "de-DE" && $0["source"] == "fastlane" })
        #expect(captures.compactMap { $0["slot"]?.intValue } == [1, 2, 3, 4, 5])
        #expect(captures[0]["captureId"] == "de-DE|APP_IPHONE_67|0")

        let mexican = try await call(ListCapturesTool(), ["locale": "es-MX", "displayType": "iphone"])
        let fallback = try #require(mexican.result["captures"]?.arrayValue?.first)
        #expect(fallback["localizedUI"] == false)
        #expect(fallback["captureId"] == "en-US|APP_IPHONE_67|0")

        let everything = try await call(ListCapturesTool())
        #expect(everything.result["captures"]?.arrayValue?.count == ScreenshotsSampleData.scope.count * 5 * 2)
    }

    @Test func aBadDisplayTypeOrLocaleIsAnInvalidArgument() async {
        await #expect(throws: MCPToolError.invalidArgument(name: "displayType", expected: "“iphone”, “iphone_duo” or “ipad”")) {
            try await call(ListCapturesTool(), ["displayType": "watch"])
        }
        await #expect(throws: MCPToolError.self) { try await call(ListCapturesTool(), ["locale": "xx-YY"]) }
    }

    @Test func theTemplateComesWithItsHistory() async throws {
        let outcome = try await call(GetTemplateTool())
        #expect(outcome.result["version"] == 4)
        #expect(outcome.result["currentVersion"] == 4)
        #expect(outcome.result["history"]?.arrayValue?.count == 4)
        #expect(outcome.result["template"]?["caption"]?["headline"]?["size"] == 112)

        let first = try await call(GetTemplateTool(), ["version": 1])
        #expect(first.result["version"] == 1)
        await #expect(throws: MCPToolError.self) { try await call(GetTemplateTool(), ["version": 9]) }
    }

    @Test func captionsCarryTheirFitAndWhoWroteThem() async throws {
        let outcome = try await call(GetCaptionsTool(), ["locales": ["de-DE"]])
        #expect(outcome.result["templateVersion"] == 4)
        let german = try #require(outcome.result["locales"]?.arrayValue?.first)
        #expect(german["locale"] == "de-DE")
        let slots = try #require(german["slots"]?.arrayValue)
        #expect(slots.count == 5)
        #expect(slots[1]["headline"] == "Deine Woche auf einer ruhigen Seite")
        #expect(slots[1]["fit"]?["fits"] == true)
        #expect(slots[2]["fit"]?["fits"] == false)
        #expect(slots[2]["fit"]?["maxLines"] == 2)
        #expect(slots.allSatisfy { $0["state"]?.stringValue != nil })
    }

    @Test func anAppWithoutATemplateSaysHowToStart() async {
        let (workspace, _) = MCPScreenshotsFixtures.workspace(.empty(primary: "en-US"))
        await #expect(throws: MCPToolError.self) { try await MCPScreenshotsFixtures.call(GetCaptionsTool(), in: workspace) }
        await #expect(throws: MCPToolError.self) { try await MCPScreenshotsFixtures.call(GetTemplateTool(), in: workspace) }
    }
}
