//
//  RenderPreviewTool.swift
//  AppLocalizer
//

import Foundation

/// `render_preview`: a slot rendered by AppLocalizer, never by the
/// assistant, optionally with a template change tried first.
struct RenderPreviewTool: MCPTool {
    static let pixelWidth = 660

    let definition = MCPToolDefinition(
        name: "render_preview",
        title: "Render preview",
        description: """
        Renders one screenshot as AppLocalizer would push it (at half size) and returns it as a PNG image: the \
        locale's capture in the template with its current caption, or the primary locale's caption when it has \
        none. Pass templatePatch to see a template change before proposing it.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "locale": MCPToolDefinition.string("A locale code such as ar-SA."),
                "slot": ["type": "integer", "description": "The slot, from 1."],
                "displayType": MCPToolDefinition.string("iphone, iphone_duo or ipad."),
                "templatePatch": ["description": .string(MeasureCaptionTool.patchDescription)],
            ],
            required: ["appId", "locale", "slot", "displayType"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let draft = try await MCPScreenshotsDraft.load(app: arguments.string("appId"), in: context.workspace)
        let locale = try draft.locale(arguments.string("locale"))
        guard let number = arguments.values["slot"]?.intValue else { throw MCPToolError.invalidArgument(name: "slot", expected: String(localized: "a number")) }
        let slot = try draft.slot(number)
        let display = try draft.displayType(arguments.string("displayType"))
        let template = try draft.patched(draft.template(), with: arguments.values["templatePatch"])
        let captions = draft.document.captions
        let caption = captions.caption(locale: locale.code, slot: slot) ?? captions.caption(locale: draft.primary.code, slot: slot)
        let capture = draft.document.captures.capture(locale: locale.code, displayType: display, slot: slot, primary: draft.primary.code)
        let layout = draft.layout(template, locale: locale, slot: slot, displayType: display, caption: caption)
        let target = draft.target(locale: locale.code, slot: slot)
        guard let data = await draft.renderPNG(layout, capture: capture?.capture, pixelWidth: Self.pixelWidth) else {
            return .failed(String(localized: "Couldn’t render the preview."), target: target)
        }
        let info: JSONValue = [
            "locale": .string(locale.code),
            "slot": .int(slot + 1),
            "displayType": .string(display.mcpValue),
            "fit": layout.headline.mcpJSON,
            "localizedUI": .bool(capture?.isInterfaceLocalized ?? false),
        ]
        return .image(data, result: info, target: target)
    }
}
