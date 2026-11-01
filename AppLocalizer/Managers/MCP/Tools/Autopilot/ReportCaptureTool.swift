//
//  ReportCaptureTool.swift
//  AppLocalizer
//

import Foundation

/// `report_capture`: one capture of a screen on a device in a language,
/// sent to the upload link first, with its attempt and score.
struct ReportCaptureTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "report_capture",
        title: "Report a screenshot capture",
        description: """
        Records a capture for the Autopilot run: the screen (id from the plan), displayType (the plan's: iphone, \
        iphone_duo, ipad, watch or vision), locale, and the upload ID the upload URL returned for its PNG (or, if \
        AppLocalizer can read it, a file path). Give the attempt (1–3) and a score from 0 to 1 with notes saying why \
        (e.g. "Keyboard covers the prompt"); the best one is picked. The PNG must be the device's full size, e.g. \
        1320 × 2868 on iPhone, 2007 × 2853 on iPhone Duo's inner display. \
        AppLocalizer reads the text in it: when the result has a check (text in another language, cut-off labels \
        or a system prompt), fix what it says and capture it again as the next attempt; a clean attempt is used \
        over one with a check. The result says how many are left.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "screen": MCPToolDefinition.string("The screen's id from the plan."),
                "displayType": MCPToolDefinition.string("The plan's device: iphone, iphone_duo, ipad, watch or vision."),
                "locale": MCPToolDefinition.string("The locale the app ran in, e.g. de-DE."),
                "upload": MCPToolDefinition.string("The upload ID the upload URL returned."),
                "file": MCPToolDefinition.string("A PNG path, when AppLocalizer can read it (prefer upload)."),
                "attempt": ["type": "integer", "description": "1, 2 or 3."],
                "score": ["type": "number", "description": "0 to 1."],
                "notes": MCPToolDefinition.string("Why it scored so, in a few words."),
            ],
            required: ["appId", "run", "screen", "displayType", "locale", "attempt", "score", "notes"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        var session = try await MCPAutopilotSession.load(arguments, in: context)
        let target = try session.captureTarget(arguments)
        let file = try await file(arguments, session: session)
        let score = arguments.values["score"]?.doubleValue ?? 0.5
        let capture: AutopilotCapture
        do {
            let report = try AutopilotCaptureReport(
                target: target, attempt: arguments.optionalInt("attempt") ?? 1, score: score, notes: arguments.optionalString("notes") ?? ""
            )
            capture = try await session.center.receiveCapture(appID: session.app.id, file: file, report: report, context: session.context)
        } catch {
            return .refused(error.localizedDescription, target: session.target(target))
        }
        if let id = try arguments.optionalString("upload") { session.center.uploads[id] = nil }
        session.refresh()
        var result: [String: JSONValue] = [
            "status": "received",
            "captured": .int(session.run.capturedCount),
            "total": .int(session.run.totalCaptures),
            "stage": .string(session.run.stage.rawValue),
        ]
        let issues = session.run.textIssues(of: capture)
        if !issues.isEmpty {
            result["check"] = .array(issues.map { ["issue": .string($0.message), "fix": .string($0.fix)] })
            result["next"] = capture.attempt < 3
                ? .string("Fix it and capture this screen again as attempt \(capture.attempt + 1).")
                : "No attempts left: say what's wrong with report_capture_problem if it can't be fixed."
        }
        return MCPToolOutcome(result: .object(result), isError: false, logLines: [.init(target: session.target(target), outcome: .proposed)])
    }

    private func file(_ arguments: MCPToolArguments, session: MCPAutopilotSession) async throws -> CaptureFile {
        if let id = try arguments.optionalString("upload"), !id.isEmpty {
            guard let upload = session.center.uploads[id], upload.runID == session.run.id else {
                throw MCPToolError.notFound(String(localized: "No upload “\(id)” for this run. Upload the PNG to the plan’s upload URL first."))
            }
            return upload.file
        }
        guard let path = try arguments.optionalString("file"), !path.isEmpty else {
            throw MCPToolError.invalidArgument(name: "upload", expected: String(localized: "the upload ID from the plan’s upload URL"))
        }
        let url = URL(filePath: (path as NSString).expandingTildeInPath)
        guard let data = try? Data(contentsOf: url) else {
            throw MCPToolError.unavailable(String(localized: "AppLocalizer can’t read \(path) (it’s sandboxed). Upload the PNG to the plan’s upload URL and pass the upload ID."))
        }
        return try await session.context.services.storeCapture(data, for: session.app)
    }
}
