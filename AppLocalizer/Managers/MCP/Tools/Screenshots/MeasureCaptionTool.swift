//
//  MeasureCaptionTool.swift
//  AppLocalizer
//

import Foundation

/// `measure_caption`: how a caption would fit, measured the way the render
/// draws it, so the assistant checks before proposing.
struct MeasureCaptionTool: MCPTool {
    static let patchDescription = "Template changes to try first, as {path: value} or a list of {op, path, value}, like propose_template's ops."

    let definition = MCPToolDefinition(
        name: "measure_caption",
        title: "Measure caption",
        description: """
        Measures a caption on a slot (from 1) with AppLocalizer's fit engine, the same one the renders use: \
        {fits, size, lines, maxLines, fill, label, glyphsMissing}. Sizes are in u; the headline shrinks from \
        the template's size to its smallest before it overflows. Pass displayType (iphone, the default, or ipad) \
        and templatePatch to measure against a template change you're considering.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "locale": MCPToolDefinition.string("A locale code such as de-DE."),
                "slot": ["type": "integer", "description": "The slot, from 1."],
                "headline": MCPToolDefinition.string("The headline to measure."),
                "subhead": MCPToolDefinition.string("A subhead, for slots that show one."),
                "displayType": MCPToolDefinition.string("iphone or ipad."),
                "templatePatch": ["description": .string(Self.patchDescription)],
            ],
            required: ["appId", "locale", "slot", "headline"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let draft = try await MCPScreenshotsDraft.load(app: arguments.string("appId"), in: context.workspace)
        let locale = try draft.locale(arguments.string("locale"))
        guard let number = arguments.values["slot"]?.intValue else { throw MCPToolError.invalidArgument(name: "slot", expected: String(localized: "a number")) }
        let slot = try draft.slot(number)
        let template = try draft.patched(draft.template(), with: arguments.values["templatePatch"])
        let display = try draft.displayType(arguments.optionalString("displayType"))
        let caption = try ScreenshotCaption(headline: arguments.string("headline"), subhead: arguments.optionalString("subhead"))
        let layout = draft.layout(template, locale: locale, slot: slot, displayType: display, caption: caption)
        var result = layout.headline.mcpJSON.objectValue ?? [:]
        result["glyphsMissing"] = .string(layout.headlineFont.missingCharacters)
        if let subhead = layout.subhead { result["subhead"] = subhead.mcpJSON }
        return .read(.object(result), target: draft.target(locale: locale.code, slot: slot))
    }
}
