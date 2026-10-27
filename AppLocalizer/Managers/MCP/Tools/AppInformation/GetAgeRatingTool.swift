//
//  GetAgeRatingTool.swift
//  AppLocalizer
//

import Foundation

/// `get_age_rating`: the age rating questionnaire of an app's version being
/// prepared, with App Store Connect's answers and the queued ones on top,
/// and the rating they add up to.
struct GetAgeRatingTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_age_rating",
        title: "Read the age rating questionnaire",
        description: """
        Returns the age rating questionnaire of an app: each question's id, text, group and the answers it takes \
        (none, infrequent or frequent; or no and yes), the current answer (App Store Connect's, with changes \
        waiting in AppLocalizer on top), and the rating they add up to. Propose answers with propose_age_rating.
        """,
        inputSchema: MCPToolDefinition.schema(
            ["appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps.")],
            required: ["appId"]
        ),
        proposalKind: nil
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        let content = try await context.workspace.services.appInformation.content(for: app, versionID: nil)
        let builder = AppInformationChangeBuilder(appID: app.id, ids: content.ids, versionString: content.version?.versionString)
        let values = builder.ageRating(content.ageRating, with: context.workspace.changes.changes(for: app.id, section: .appInformation))
        let result: JSONValue = [
            "app": ["appId": .string(app.id), "name": .string(app.name)],
            "version": content.version.map { .string($0.versionString) } ?? .null,
            "rating": .string(values.preview.effective.title),
            "questions": .array(AgeRatingQuestion.allCases.map { $0.mcpJSON(current: values) }),
        ]
        return .read(result, target: String(localized: "\(app.name) · Age Rating"))
    }
}
