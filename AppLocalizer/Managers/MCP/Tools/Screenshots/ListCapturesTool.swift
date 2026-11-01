//
//  ListCapturesTool.swift
//  AppLocalizer
//

import Foundation

/// `list_captures`: each locale's capture per slot, and whether it shows
/// the locale's own interface or the primary's.
struct ListCapturesTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "list_captures",
        title: "List captures",
        description: """
        Lists the captures (real screenshots of the app) each locale in scope uses, per display type and slot \
        (from 1). localizedUI is false when a locale has none of its own and shows the primary locale's \
        interface. Pass captureId to get_capture to see one.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "displayType": MCPToolDefinition.string("iphone, iphone_duo or ipad. Leave it out for all three."),
                "locale": MCPToolDefinition.string("A locale code such as de-DE. Leave it out for every locale in scope."),
            ],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let draft = try await MCPScreenshotsDraft.load(app: arguments.string("appId"), in: context.workspace)
        let displays = try arguments.optionalString("displayType").map { try [draft.displayType($0)] } ?? ScreenshotDisplayType.rendered
        let locales = try arguments.optionalString("locale").map { try [draft.locale($0)] } ?? draft.scopeLocales
        var captures: [JSONValue] = []
        for locale in locales {
            for display in displays {
                for slot in 0..<draft.document.slotCount {
                    guard let resolved = draft.document.captures.capture(
                        locale: locale.code, displayType: display, slot: slot, primary: draft.primary.code
                    ) else { continue }
                    let capture = resolved.capture
                    captures.append([
                        "captureId": .string(capture.id),
                        "locale": .string(locale.code),
                        "displayType": .string(display.mcpValue),
                        "slot": .int(slot + 1),
                        "source": .string(capture.source.rawValue),
                        "localizedUI": .bool(resolved.isInterfaceLocalized),
                        "pixelSize": ["width": .int(capture.pixelSize.width), "height": .int(capture.pixelSize.height)],
                    ])
                }
            }
        }
        return .read(["appId": .string(draft.app.id), "captures": .array(captures)], target: draft.target)
    }
}
