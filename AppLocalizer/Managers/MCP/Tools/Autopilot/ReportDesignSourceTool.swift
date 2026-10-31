//
//  ReportDesignSourceTool.swift
//  AppLocalizer
//

import Foundation

/// `report_design_source`: what the assistant found in the connected
/// design project, so the person sees it's the right system.
struct ReportDesignSourceTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "report_design_source",
        title: "Report what the design project holds",
        description: """
        After opening the app's connected design project (Claude Design, a Figma file), tell AppLocalizer what \
        you found: its title ("Northpier Brand · design system"), colors [{name, hex}], typefaces, logo and \
        voice. AppLocalizer shows it under Connect a Design Project. AppLocalizer can't open these sources \
        itself.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "title": MCPToolDefinition.string("The system or project's name and kind."),
                "colors": [
                    "type": "array",
                    "items": ["type": "object", "properties": ["name": ["type": "string"], "hex": ["type": "string"]], "required": ["name", "hex"]],
                ],
                "typefaces": MCPToolDefinition.string("e.g. New York Bold for headlines · SF Pro Text for the rest."),
                "logo": MCPToolDefinition.string("e.g. Moon mark, light and dark."),
                "voice": MCPToolDefinition.string("e.g. Calm, short sentences, no exclamation marks."),
            ],
            required: ["appId", "title"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        let target = String(localized: "\(app.name) · Design project")
        guard let center = context.workspace.services.screenshots.autopilot, center.designProject(for: app.id) != nil else {
            return .refused(String(localized: "\(app.name) has no design project connected. The person connects one in Screenshots → Design project."), target: target)
        }
        let colors = try (arguments.optionalArray("colors") ?? []).compactMap { item -> DesignSwatch? in
            guard let name = item["name"]?.stringValue, let hex = item["hex"]?.stringValue, TemplateColor(hex) != nil else { return nil }
            return DesignSwatch(name: name, hex: hex.uppercased())
        }
        let summary = try DesignSourceSummary(
            title: arguments.string("title"), colors: Array(colors.prefix(8)), typefaces: arguments.optionalString("typefaces"),
            logo: arguments.optionalString("logo"), voice: arguments.optionalString("voice"), updated: .now, readBy: context.clientName
        )
        center.setDesignSummary(summary, for: app.id)
        return MCPToolOutcome(result: ["status": "saved"], isError: false, logLines: [.init(target: target, outcome: .proposed)])
    }
}
