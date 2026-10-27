//
//  ProposePrivacyAnswersTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_privacy_answers`: an assistant's App Privacy answers with
/// confidence and evidence, open questions for what the code can't show,
/// and what it read. Everything lands in the worksheet as unreviewed
/// suggestions; an answer the person gave stays theirs and the different
/// one waits beside it as a conflict. Nothing goes to App Store Connect,
/// which has no API for App Privacy.
struct ProposePrivacyAnswersTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_privacy_answers",
        title: "Propose App Privacy answers",
        description: """
        Proposes App Privacy answers for an app into AppLocalizer's worksheet, where the person reviews each one. \
        Send collects (the first question), answers: [{type, collected, purposes, linked, tracking, confidence, \
        rationale, evidence: [{kind, sdk, version, entry, path, line, excerpt}]}] with ids from \
        get_privacy_questionnaire, open_questions: [{id, question, affects, if_yes: {summary, collected, purposes, \
        linked}, if_no: {...}}] for what the code can't show (such as what a server keeps), and scan: {repository, \
        commit, sdks, manifests_read, tracking_signals, could_not_see}. Each answer is "queued" (waits for review), \
        "conflict" (the person answered differently; they pick), "unchanged" or "refused" with the reason: fix it \
        and send it again. Set final: false while more calls follow; the scan ends with the last call.
        """,
        inputSchema: Self.schema,
        proposalKind: .appInformation
    )

    /// The call's arguments, read.
    private struct Request {
        var answers: [MCPPrivacyAnswer]
        var questions: [MCPPrivacyQuestion]
        var collects: Bool?
        var scan: PrivacyScan?
        var isFinal: Bool

        init(_ arguments: MCPToolArguments, client: String, date: Date) throws {
            answers = try (arguments.optionalArray("answers") ?? []).map { item in
                guard let object = item.objectValue else {
                    throw MCPToolError.invalidArgument(name: "answers", expected: String(localized: "a list of {type, collected, purposes, …} objects"))
                }
                return MCPPrivacyAnswer(object, client: client)
            }
            questions = try (arguments.optionalArray("open_questions") ?? []).enumerated().map { index, item in
                guard let object = item.objectValue else {
                    throw MCPToolError.invalidArgument(name: "open_questions", expected: String(localized: "a list of {id, question, affects, …} objects"))
                }
                return MCPPrivacyQuestion(object, index: index, client: client)
            }
            collects = arguments.values["collects"]?.boolValue
            scan = try arguments.optionalObject("scan").map { MCPPrivacyScanDetails.scan($0, client: client, at: date) }
            isFinal = arguments.values["final"]?.boolValue ?? true
        }
    }

    /// What applying a request did, item by item.
    private struct Report {
        var results: [JSONValue] = []
        var logLines: [MCPToolOutcome.LogLine] = []
        var outcomes: [PrivacyProposalOutcome] = []
        var collects: PrivacyProposalOutcome?
    }

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        let date = Date()
        let request = try Request(arguments, client: context.clientName, date: date)
        var report = Report()
        context.workspace.services.appInformation.privacy.update(app.id) { worksheet in
            report = Self.apply(request, to: &worksheet, app: app, client: context.clientName, at: date)
        }
        for question in request.questions {
            guard let refusal = question.refusal else { continue }
            let target = String(localized: "\(app.name) · App Privacy · question")
            report.logLines.append(MCPToolOutcome.LogLine(target: target, outcome: .refused, reason: refusal))
        }
        if report.logLines.isEmpty {
            report.logLines.append(MCPToolOutcome.LogLine(target: String(localized: "\(app.name) · App Privacy"), outcome: .proposed))
        }
        var summary: [String: JSONValue] = [
            "results": .array(report.results),
            "queued": .int(report.outcomes.count { $0 == .queued }),
            "conflicts": .int(report.outcomes.count { $0 == .conflict }),
            "refused": .int(request.answers.count { $0.suggestion == nil }),
            "note": "Suggestions wait in AppLocalizer's App Privacy worksheet for the person to review. Nothing is sent to App Store Connect.",
        ]
        if let collects = report.collects { summary["collects"] = .string(collects.rawValue) }
        if !request.questions.isEmpty { summary["openQuestions"] = Self.questionsResult(request.questions) }
        return MCPToolOutcome(result: .object(summary), isError: false, logLines: report.logLines)
    }

    /// Records the scan, the first question, every answer and the open
    /// questions in the worksheet; ends the scan when the call is final.
    private static func apply(_ request: Request, to worksheet: inout PrivacyWorksheet, app: StoreApp, client: String, at date: Date) -> Report {
        var report = Report()
        worksheet.beginScan(by: client, at: date)
        if let scan = request.scan { worksheet.recordScanDetails(scan, at: date) }
        if let collects = request.collects {
            report.collects = worksheet.proposeCollects(collects, confidence: .high, by: client)
        }
        for answer in request.answers {
            let target = String(localized: "\(app.name) · App Privacy · \(answer.type?.name ?? answer.typeText)")
            guard let type = answer.type, let suggestion = answer.suggestion else {
                let reason = answer.refusal ?? ""
                report.results.append(["type": .string(answer.typeText), "status": "refused", "reason": .string(reason)])
                report.logLines.append(MCPToolOutcome.LogLine(target: target, outcome: .refused, reason: reason))
                continue
            }
            let outcome = worksheet.propose(suggestion, for: type, at: date)
            report.outcomes.append(outcome)
            report.results.append(result(type, outcome: outcome))
            report.logLines.append(MCPToolOutcome.LogLine(target: target, outcome: outcome == .unchanged ? .read : .proposed))
        }
        for question in request.questions {
            guard let open = question.question else { continue }
            worksheet.ask(open, at: date)
        }
        if request.isFinal { worksheet.finishScan(at: date) }
        return report
    }

    private static func result(_ type: PrivacyDataType, outcome: PrivacyProposalOutcome) -> JSONValue {
        var result: [String: JSONValue] = ["type": .string(type.rawValue), "status": .string(outcome.rawValue)]
        switch outcome {
        case .queued: break
        case .conflict: result["note"] = "The person answered this type differently. Both answers are shown; they pick one."
        case .unchanged: result["note"] = "That's already the worksheet's answer; the evidence was updated."
        }
        return .object(result)
    }

    /// "queued", or each question's status when some were refused.
    private static func questionsResult(_ questions: [MCPPrivacyQuestion]) -> JSONValue {
        guard questions.contains(where: { $0.refusal != nil }) else { return "queued" }
        return .array(questions.map { question in
            if let refusal = question.refusal {
                return ["id": .string(question.id), "status": "refused", "reason": .string(refusal)]
            }
            return ["id": .string(question.id), "status": "queued"]
        })
    }

    private static var schema: JSONValue {
        let evidence = MCPToolDefinition.schema([
            "kind": MCPToolDefinition.string("sdk_manifest, dependency, info_plist, entitlement or code."),
            "sdk": MCPToolDefinition.string("The SDK, e.g. RevenueCat."),
            "version": MCPToolDefinition.string("The SDK's version, e.g. 5.14.2."),
            "entry": MCPToolDefinition.string("The manifest key or dependency, e.g. NSPrivacyCollectedDataTypePurchaseHistory."),
            "path": MCPToolDefinition.string("The file, relative to the repository."),
            "line": ["type": "integer", "description": "The line in path."],
            "excerpt": MCPToolDefinition.string("A short excerpt of the code or manifest."),
        ])
        let effect: JSONValue = [
            "type": "object",
            "description": "What this answer means: a summary, and the answer it gives the affected types.",
            "properties": [
                "summary": MCPToolDefinition.string("e.g. Email Address becomes collected, linked, for App Functionality."),
                "collected": ["type": "boolean"],
                "purposes": ["type": "array", "items": ["type": "string"]],
                "linked": ["type": "boolean"],
                "tracking": ["type": "boolean"],
            ],
        ]
        return MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "collects": ["type": "boolean", "description": "Do you or your third-party partners collect data from this app?"],
                "answers": [
                    "type": "array",
                    "items": MCPToolDefinition.schema(
                        [
                            "type": MCPToolDefinition.string("A data type id from get_privacy_questionnaire, e.g. purchases."),
                            "collected": ["type": "boolean"],
                            "purposes": ["type": "array", "items": ["type": "string"], "description": "Purpose ids, e.g. APP_FUNCTIONALITY."],
                            "linked": ["type": "boolean"],
                            "tracking": ["type": "boolean"],
                            "confidence": ["type": "string", "enum": ["high", "medium", "low"]],
                            "rationale": MCPToolDefinition.string("Why, in a sentence the person can check."),
                            "evidence": ["type": "array", "items": evidence],
                        ],
                        required: ["type", "collected"]
                    ),
                ],
                "open_questions": [
                    "type": "array",
                    "items": MCPToolDefinition.schema(
                        [
                            "id": MCPToolDefinition.string("A stable id, e.g. q1."),
                            "question": MCPToolDefinition.string("A yes-or-no question for the person."),
                            "affects": ["type": "array", "items": ["type": "string"]],
                            "if_yes": effect,
                            "if_no": effect,
                        ],
                        required: ["question"]
                    ),
                ],
                "scan": [
                    "type": "object",
                    "properties": [
                        "repository": MCPToolDefinition.string("e.g. northpier/lumen."),
                        "commit": MCPToolDefinition.string("The commit you read."),
                        "sdks": ["type": "array", "items": MCPToolDefinition.schema([
                            "name": MCPToolDefinition.string("The SDK."),
                            "version": MCPToolDefinition.string("Its version."),
                        ])],
                        "manifests_read": ["type": "array", "items": ["type": "string"]],
                        "tracking_signals": MCPToolDefinition.string("What you found about tracking."),
                        "could_not_see": MCPToolDefinition.string("What the code can't show, e.g. what your servers keep."),
                    ],
                ],
                "final": ["type": "boolean", "description": "false while more calls follow. Defaults to true."],
            ],
            required: ["appId"]
        )
    }
}
