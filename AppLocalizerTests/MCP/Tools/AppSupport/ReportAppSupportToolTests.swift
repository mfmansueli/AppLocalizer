//
//  ReportAppSupportToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `report_app_support`: the assistant tells AppLocalizer the devices and
/// languages the project supports.
@MainActor
@Suite("report_app_support")
struct ReportAppSupportToolTests {
    private static let appID = DebugFixtures.AppID.lumen

    private func workspace(_ center: AppSupportCenter?) -> MCPWorkspace {
        var storePage = DebugStorePageServices()
        storePage.appSupport = center
        return MCPTestFixtures.workspace(storePage: storePage)
    }

    private func call(_ arguments: [String: JSONValue], center: AppSupportCenter?) async throws -> MCPToolOutcome {
        let context = MCPToolContext(workspace: workspace(center), clientName: "Claude Code")
        return try await ReportAppSupportTool().call(MCPToolArguments(arguments), in: context)
    }

    @Test func theReportIsKeptAndTheMissingLanguagesComeBack() async throws {
        let center = AppSupportCenter()
        let outcome = try await call([
            "appId": .string(Self.appID),
            "targets": ["Lumen (iOS, visionOS)", "LumenWatch Watch App"],
            "devices": [
                ["device": "ipad", "reason": "Lumen runs on iPad"],
                ["device": "watch", "reason": "Lumen has a watch app, LumenWatch"],
                ["device": "iphone", "reason": "ignored"],
                ["device": "toaster", "reason": "ignored"],
            ],
            "languages": [
                ["code": "en", "translated": 418, "total": 418], ["code": "pl", "translated": 412, "total": 418],
                ["code": "he", "note": "Right to left"], ["code": "tlh"],
            ],
            "languageSource": "Localizable.xcstrings",
        ], center: center)

        let profile = try #require(center.profile(for: Self.appID))
        #expect(profile.targets == ["Lumen (iOS, visionOS)", "LumenWatch Watch App"])
        #expect(profile.devices.map(\.displayType) == [.iPad, .watch])
        #expect(profile.languages.map(\.code) == ["en", "pl", "he", "tlh"])
        #expect(profile.languageSource == "Localizable.xcstrings")
        #expect(profile.reportedBy == "Claude Code")
        #expect(outcome.isError == false)
        #expect(outcome.result["status"] == "saved")
        #expect(outcome.result["devices"] == ["iphone", "ipad", "watch"])
        #expect(outcome.result["notOnAppStore"]?.arrayValue?.compactMap { $0["locale"]?.stringValue } == ["pl", "he"])
        #expect(outcome.result["unknownLanguages"] == ["tlh"])
        #expect(outcome.result["next"]?.stringValue?.contains("suggest_fields") == true)
    }

    @Test func withoutACenterItsRefused() async throws {
        let outcome = try await call(["appId": .string(Self.appID), "languages": [["code": "pl"]]], center: nil)
        #expect(outcome.result["status"] == "refused")
    }

    @Test func itIsServedAndChangesState() {
        let definition = MCPToolbox.standard.tool(named: "report_app_support")?.definition
        #expect(definition?.isReadOnly == false)
        #expect(definition?.proposalKind == nil)
        #expect(Set(definition?.inputSchema["required"]?.arrayValue?.compactMap(\.stringValue) ?? []) == ["appId", "languages"])
    }

    @Test(arguments: [("watch", ScreenshotDisplayType.watch), ("APP_WATCH_ULTRA", .watch), ("vision", .visionPro), ("visionOS", .visionPro), ("ipad", .iPad)])
    func deviceNamesAreUnderstood(name: String, display: ScreenshotDisplayType) {
        #expect(ScreenshotDisplayType(mcpValue: name) == display)
    }
}
#endif
