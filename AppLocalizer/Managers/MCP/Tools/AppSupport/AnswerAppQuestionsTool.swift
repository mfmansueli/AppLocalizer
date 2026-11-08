//
//  AnswerAppQuestionsTool.swift
//  AppLocalizer
//

import Foundation

/// `answer_app_questions`: what the assistant found out about the app for
/// the questions AppLocalizer asked. Remembered per app and merged with
/// what's known, so a later run starts from it.
struct AnswerAppQuestionsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "answer_app_questions",
        title: "Answer AppLocalizer's questions about the app",
        description: """
        Tells AppLocalizer what it asked about the app (next_step says answer_app_questions, and get_store_page lists \
        appQuestions): the App Preview's story, what moves in the app, how it should sound, what sets it apart, its \
        voice and what's off limits. Answer from the project, in the app's own words; leave the answer out when the \
        project doesn't say. With music_track and music_reason, also the library track that fits the app: it becomes the \
        App Preview's music unless the person chose one. AppLocalizer keeps the answers for every later run and asks \
        again once they're old.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "answers": [
                    "type": "array",
                    "description": "One per question: {\"question\": \"soundMood\", \"answer\": \"Quiet and warm…\"}.",
                    "items": MCPToolDefinition.schema(
                        [
                            "question": MCPToolDefinition.string("The question's id."),
                            "answer": MCPToolDefinition.string("The answer; left out when the project doesn't say."),
                        ],
                        required: ["question"]
                    ),
                ],
                "music_track": MCPToolDefinition.string("The library track that fits the app, from musicLibrary."),
                "music_reason": MCPToolDefinition.string("Why it fits, in one sentence the person reads."),
            ],
            required: ["appId"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        let target = String(localized: "\(app.name) · About the app")
        guard let center = context.workspace.services.storePage.appSupport else {
            return .refused(String(localized: "This AppLocalizer can’t keep what it learns about the app."), target: target)
        }
        var update = AppKnowledge()
        var unknown: [JSONValue] = []
        for item in try arguments.optionalArray("answers") ?? [] {
            guard let id = item["question"]?.stringValue else { continue }
            guard let question = AppQuestion(rawValue: id) else {
                unknown.append(.string(id))
                continue
            }
            update.set(question, text: item["answer"]?.stringValue, by: context.clientName, at: .now)
        }
        update.music = try Self.music(arguments)
        guard !update.isEmpty else {
            throw MCPToolError.invalidArgument(name: "answers", expected: String(localized: "at least one answer, or music_track"))
        }
        center.remember(update, for: app.id)
        var result: [String: JSONValue] = [
            "status": "saved",
            "stillDue": .array((center.knowledge(for: app.id) ?? AppKnowledge()).due(now: .now).map { .string($0.rawValue) }),
        ]
        if !unknown.isEmpty { result["unknownQuestions"] = .array(unknown) }
        if let music = update.music, let autopilot = context.workspace.services.screenshots.autopilot {
            result["musicApplied"] = .bool(autopilot.suggestPreviewMusic(music, appID: app.id))
        }
        return MCPToolOutcome(result: .object(result), isError: false, logLines: [.init(target: target, outcome: .proposed)])
    }

    /// The track and its reason; nil when none was sent.
    private static func music(_ arguments: MCPToolArguments) throws -> AppMusicPick? {
        guard let value = try arguments.optionalString("music_track"), !value.isEmpty else { return nil }
        guard let track = AppPreviewTrack(rawValue: value), track.isLibrary else {
            let ids = AppPreviewTrack.library.map(\.rawValue).formatted(.list(type: .or))
            throw MCPToolError.invalidArgument(name: "music_track", expected: String(localized: "a library track: \(ids)"))
        }
        return try AppMusicPick(track: track, reason: arguments.optionalString("music_reason") ?? "")
    }
}
