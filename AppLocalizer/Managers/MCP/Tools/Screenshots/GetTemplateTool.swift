//
//  GetTemplateTool.swift
//  AppLocalizer
//

import Foundation

/// `get_template`: the template JSON (design README §3) and its history.
struct GetTemplateTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_template",
        title: "Get screenshot template",
        description: """
        Reads an app's screenshot template: one JSON document for every locale and display type, with sizes in u \
        (the canvas's short side ÷ 1320), the caption's text styles and fit rules, fonts and per-script fallbacks, \
        right-to-left rules, the device frame, and per-slot overrides under slots.<n>.over (n from 0 here). \
        Paths in propose_template are the dotted paths of this JSON, e.g. caption.headline.size. Also returns \
        the history of versions. Pass version for an older one.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "version": ["type": "integer", "description": "A template version number. Leave it out for the current one."],
            ],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let draft = try await MCPScreenshotsDraft.load(app: arguments.string("appId"), in: context.workspace)
        _ = try draft.template()
        guard let history = draft.document.history else { return .failed(String(localized: "There’s no template yet."), target: draft.target) }
        let number = arguments.values["version"]?.intValue ?? history.currentNumber
        guard let version = history.version(number) else {
            throw MCPToolError.notFound(String(localized: "There’s no template v\(number); the current version is v\(history.currentNumber)."))
        }
        let versions = history.versions.map { version -> JSONValue in
            [
                "version": .int(version.number),
                "date": .string(version.date.formatted(.iso8601)),
                "author": .string(version.author.title),
                "note": .string(version.note),
            ]
        }
        let result: JSONValue = [
            "appId": .string(draft.app.id),
            "version": .int(version.number),
            "currentVersion": .int(history.currentNumber),
            "template": version.template.json,
            "history": .array(versions),
        ]
        return .read(result, target: draft.target)
    }
}
