//
//  ReportAppSupportTool.swift
//  AppLocalizer
//

import Foundation

/// `report_app_support`: what the app's Xcode project supports — its
/// targets, the devices they run on and the languages its strings are
/// translated into — so Store Page can suggest pages for languages the App
/// Store doesn't have yet, and Screenshot Autopilot plans every device.
struct ReportAppSupportTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "report_app_support",
        title: "Report the devices and languages the app supports",
        description: """
        After reading the app's Xcode project, tell AppLocalizer what it supports: the targets ("Lumen (iOS, \
        visionOS)", "LumenWatch Watch App"), the devices they run on besides iPhone (ipad, watch, vision, mac when it has a macOS \
        target or Mac Catalyst, so the Mac App Store takes Mac screenshots of its own (not when it only runs on Mac as an iPad app), \
        and iphone_duo when the iOS target builds with the iOS 27.1 SDK or later, which makes iPhone Duo screenshots required from \
        April 2027) with why ("Lumen runs on iPad", "Lumen has a watch app, LumenWatch", "1.4 adds visionOS", "Lumen supports Mac \
        Catalyst", "Built with the iOS 27.1 SDK"), and every language in \
        its string catalogs (Localizable.xcstrings) with how many strings are translated, plus a note when it \
        matters ("Right to left; tested in LumenUITests"). AppLocalizer compares the languages with the App \
        Store page: the ones it doesn't have yet are suggested as new pages, and Autopilot plans each device. \
        With look, also what the project says of the app's look (accent and theme colors, fonts, dark mode), its \
        icon in one sentence, who it's for and when they use it, and the header scene template you recommend from \
        that (night, land, window, horizon, hero or pattern) with a one-sentence reason: AppLocalizer's plan shows \
        it, and the header and search prompts use it. Each report replaces the last (the look stays until a report \
        has one). AppLocalizer can't open the project itself.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "targets": ["type": "array", "items": ["type": "string"], "description": "The app's targets with their platforms."],
                "devices": [
                    "type": "array",
                    "description": "Devices besides iPhone: ipad, mac, watch, vision or iphone_duo, each with the reason.",
                    "items": [
                        "type": "object",
                        "properties": ["device": ["type": "string"], "reason": ["type": "string"]],
                        "required": ["device", "reason"],
                    ],
                ],
                "languages": [
                    "type": "array",
                    "description": "Every language in the string catalogs, the development language too.",
                    "items": [
                        "type": "object",
                        "properties": [
                            "code": ["type": "string", "description": "The catalog's code, e.g. pl, pt-BR, zh-Hans."],
                            "translated": ["type": "integer"],
                            "total": ["type": "integer"],
                            "note": ["type": "string"],
                        ],
                        "required": ["code"],
                    ],
                ],
                "languageSource": MCPToolDefinition.string("Where the languages come from, e.g. Localizable.xcstrings."),
                "look": AppLookProfile.mcpSchema,
            ],
            required: ["appId", "languages"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        let target = String(localized: "\(app.name) · Devices and languages")
        guard let center = context.workspace.services.storePage.appSupport else {
            return .refused(String(localized: "This AppLocalizer can’t keep what the project supports."), target: target)
        }
        var unknown: [JSONValue] = []
        let languages = try (arguments.optionalArray("languages") ?? []).compactMap { item -> ProjectLanguage? in
            guard let code = item["code"]?.stringValue?.trimmingCharacters(in: .whitespaces), !code.isEmpty else { return nil }
            let language = ProjectLanguage(
                code: code, translated: item["translated"]?.intValue, total: item["total"]?.intValue, note: item["note"]?.stringValue
            )
            if language.storeLocale == nil { unknown.append(.string(code)) }
            return language
        }
        let devices = try (arguments.optionalArray("devices") ?? []).compactMap { item -> SupportedDevice? in
            guard let name = item["device"]?.stringValue, let display = ScreenshotDisplayType(mcpValue: name), display != .iPhone else { return nil }
            return SupportedDevice(displayType: display, reason: item["reason"]?.stringValue ?? "")
        }
        let profile = try AppSupportProfile(
            targets: arguments.optionalStrings("targets") ?? [], devices: devices, languages: languages,
            languageSource: arguments.optionalString("languageSource"), reportedBy: context.clientName,
            look: AppLookProfile.mcp(arguments.optionalObject("look")), updated: .now
        )
        center.report(profile, for: app.id)
        let storeLocales = await Self.storeLocales(of: app, in: context)
        let missing = profile.languagesMissing(from: storeLocales).compactMap(\.storeLocale)
        var result: [String: JSONValue] = [
            "status": "saved",
            "devices": .array(([.iPhone] + devices.map(\.displayType)).map { .string($0.mcpValue) }),
            "notOnAppStore": .array(missing.map { ["locale": .string($0.code), "name": .string($0.name)] }),
        ]
        if !unknown.isEmpty { result["unknownLanguages"] = .array(unknown) }
        if !missing.isEmpty {
            result["next"] = .string(String(localized: """
            These languages aren’t on the App Store yet. Draft their pages with suggest_fields (one locale each); \
            the person adds them in Store Page.
            """))
        }
        return MCPToolOutcome(result: .object(result), isError: false, logLines: [.init(target: target, outcome: .proposed)])
    }

    /// The App Store languages of the app's editable version, or none when
    /// the listing can't be read.
    private static func storeLocales(of app: StoreApp, in context: MCPToolContext) async -> [String] {
        guard let content = try? await context.workspace.services.storePage.content(for: app, versionID: nil) else { return [] }
        return content.locales.map(\.code)
    }
}
