//
//  ProposeAgeRatingTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_age_rating`: an assistant's answers to the age rating
/// questionnaire, each with its evidence. Each answer is queued as the same
/// change the Age Rating page makes, tagged with the assistant and blocked
/// until the person ticks Confirmed; the evidence is kept for the page's
/// popover.
struct ProposeAgeRatingTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_age_rating",
        title: "Propose age rating answers",
        description: """
        Proposes answers to an app's age rating questionnaire: answers: [{question, answer, why, evidence}], with \
        question ids and answers from get_age_rating, evidence as "file:line — finding" strings, and could_not_see \
        for what you couldn't check. Each answer is queued in AppLocalizer (status "queued") and waits until the \
        person confirms it; "unchanged" means App Store Connect already has it; "refused" says why. Nothing \
        reaches App Store Connect until the person pushes.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "answers": [
                    "type": "array",
                    "items": MCPToolDefinition.schema(
                        [
                            "question": MCPToolDefinition.string("A question id from get_age_rating, e.g. userGeneratedContent."),
                            "answer": MCPToolDefinition.string("none, infrequent, frequent, no or yes."),
                            "why": MCPToolDefinition.string("Why, in a sentence the person can check."),
                            "evidence": ["type": "array", "items": ["type": "string"], "description": "e.g. Lumen/Share/ShareSheet.swift:12 — posts entries"],
                        ],
                        required: ["question", "answer"]
                    ),
                ],
                "could_not_see": MCPToolDefinition.string("What the code can't show, e.g. content on your servers."),
            ],
            required: ["appId", "answers"]
        ),
        proposalKind: .appInformation
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        let items = try arguments.array("answers")
        let couldNotSee = try arguments.optionalString("could_not_see")
        let services = context.workspace.services.appInformation
        let content = try await services.content(for: app, versionID: nil)
        guard content.ids.ageRatingDeclarationID != nil else {
            return .failed(String(localized: "\(app.name) has no age rating declaration to answer yet."), target: String(localized: "\(app.name) · Age Rating"))
        }
        let builder = AppInformationChangeBuilder(appID: app.id, ids: content.ids, versionString: content.version?.versionString)
        var notes = services.notes.notes(for: app.id)
        var results: [JSONValue] = []
        var logLines: [MCPToolOutcome.LogLine] = []
        for item in items {
            let object = item.objectValue ?? [:]
            let questionText = object["question"]?.stringValue ?? ""
            let target = String(localized: "\(app.name) · Age Rating · \(questionText)")
            guard let question = AgeRatingQuestion.matching(questionText) else {
                let reason = String(localized: "Unknown question “\(questionText)”. Use an id from get_age_rating.")
                results.append(["question": .string(questionText), "status": "refused", "reason": .string(reason)])
                logLines.append(MCPToolOutcome.LogLine(target: target, outcome: .refused, reason: reason))
                continue
            }
            guard let answer = object["answer"].flatMap(AgeRatingAnswer.matching), question.answers.contains(answer) else {
                let allowed = question.answers.map(\.rawValue).formatted(.list(type: .or))
                let reason = String(localized: "“\(question.rawValue)” is answered \(allowed).")
                results.append(["question": .string(question.rawValue), "status": "refused", "reason": .string(reason)])
                logLines.append(MCPToolOutcome.LogLine(target: target, outcome: .refused, reason: reason))
                continue
            }
            let change = builder.ageAnswerChange(question, from: content.ageRating, to: answer, source: context.source, confirmed: false)
            guard let change else {
                results.append(["question": .string(question.rawValue), "status": "unchanged"])
                logLines.append(MCPToolOutcome.LogLine(target: target, outcome: .read))
                continue
            }
            context.workspace.changes.upsert(change)
            notes.ageEvidence[question.rawValue] = AssistantEvidence(
                client: context.clientName,
                summary: answer.title,
                why: object["why"]?.stringValue ?? "",
                evidence: (object["evidence"]?.arrayValue ?? []).compactMap(\.stringValue),
                couldNotSee: couldNotSee
            )
            results.append(["question": .string(question.rawValue), "status": "queued", "changeId": .string(change.id)])
            logLines.append(MCPToolOutcome.LogLine(target: target, outcome: .proposed))
        }
        services.notes.setNotes(notes, for: app.id)
        let summary: JSONValue = [
            "results": .array(results),
            "note": "Each answer waits in AppLocalizer until the person confirms it on the Age Rating page.",
        ]
        return MCPToolOutcome(result: summary, isError: false, logLines: logLines)
    }
}
