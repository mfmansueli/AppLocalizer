//
//  ReviseAppPreviewTool.swift
//  AppLocalizer
//

import Foundation

/// `revise_app_preview`: the App Preview's new version after the person
/// asked for changes at Watch the App Preview. Only the cut, the captions'
/// size, the end card, the look and the music change; the recordings stay.
struct ReviseAppPreviewTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "revise_app_preview",
        title: "Revise the App Preview",
        description: """
        Sends the App Preview's new version after the person asked for changes (next_step's \
        revise_app_preview gives the note and the current cut): which plan screens play and in what order, \
        its length, the captions' size, the end card, optionally its look and a library track. Say what \
        changed in changes. AppLocalizer makes every App Preview again with it and shows the person the new \
        version. The recordings stay as they are.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "changes": MCPToolDefinition.string("What changed, in a short sentence the person reads: “Slower pace, starts with Search”."),
                "screens": Self.screensSchema,
                "seconds": Self.secondsSchema,
                "captionScale": Self.captionScaleSchema,
                "endCard": Self.endCardSchema,
                "appPreviewTemplate": Self.lookSchema,
                "music": MCPToolDefinition.string("Optional: a library track (warm_acoustic, calm_piano, bright_pop) for other music."),
            ],
            required: ["appId", "run", "changes"]
        ),
        proposalKind: .screenshots
    )

    private static let screensSchema: JSONValue = [
        "type": "array", "items": ["type": "string"],
        "description": "The plan screen IDs that play, in order. Leave out to keep the current order.",
    ]
    private static let secondsSchema: JSONValue = [
        "type": "number", "description": "The App Preview's length, 15 to 30 seconds. Longer is a slower pace.",
    ]
    private static let captionScaleSchema: JSONValue = [
        "type": "number", "description": "The captions' size against the template's, 0.8 to 1.4.",
    ]
    private static let endCardProperties: JSONValue = ["caption": ["type": "boolean"], "screen": ["type": "string"]]
    private static let endCardSchema: JSONValue = [
        "type": "object",
        "description": "The end card: caption false shows only the app's name; screen is the plan screen whose caption it shows.",
        "properties": endCardProperties,
    ]
    private static let lookSchema: JSONValue = [
        "type": "object",
        "description": "Optional: the App Preview's look as template fields (as get_template returns them) and/or ops, laid on its current look.",
    ]

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        let changes = try arguments.string("changes").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !changes.isEmpty else {
            throw MCPToolError.invalidArgument(name: "changes", expected: String(localized: "what changed, in a sentence"))
        }
        let review = session.run.previewReview ?? AutopilotPreviewReview()
        do {
            let cut = try Self.cut(arguments, over: review.cut, session: session)
            let track = try arguments.optionalString("music").map { value in
                guard let track = AppPreviewTrack(rawValue: value), track.isLibrary else {
                    let ids = AppPreviewTrack.library.map(\.rawValue).formatted(.list(type: .or))
                    throw MCPToolError.invalidArgument(name: "music", expected: String(localized: "a library track: \(ids)"))
                }
                return track
            }
            let look = try Self.look(arguments, run: session.run, fonts: session.context.services.fonts)
            try await session.center.revisePreview(
                AutopilotPreviewDraft(cut: cut, changes: changes, look: look, track: track, client: context.clientName),
                appID: session.app.id, context: session.context
            )
        } catch let error as MCPToolError {
            throw error
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        var updated = session
        updated.refresh()
        let version = updated.run.previewReview?.version ?? review.version
        let result: JSONValue = ["status": "revised", "version": .int(version), "changes": .string(changes)]
        return MCPToolOutcome(
            result: result, isError: false, logLines: [.init(target: "\(session.target) · App Preview v\(version)", outcome: .proposed)]
        )
    }

    /// The cut from the arguments, over the current one: what isn't sent
    /// stays.
    @MainActor
    static func cut(_ arguments: MCPToolArguments, over current: AppPreviewCut, session: MCPAutopilotSession) throws -> AppPreviewCut {
        var cut = current
        if let screens = try arguments.optionalStrings("screens") {
            guard !screens.isEmpty else {
                throw MCPToolError.invalidArgument(name: "screens", expected: String(localized: "at least one of the plan’s screen IDs"))
            }
            cut.screenIDs = try screens.map { try session.screen($0).id }
        }
        if let value = arguments.values["seconds"], !value.isNull {
            guard let seconds = value.doubleValue, AppPreviewCut.secondsRange.contains(seconds) else {
                throw MCPToolError.invalidArgument(name: "seconds", expected: String(localized: "a length from 15 to 30 seconds"))
            }
            cut.seconds = seconds
        }
        if let value = arguments.values["captionScale"], !value.isNull {
            guard let scale = value.doubleValue, AppPreviewCut.captionScaleRange.contains(scale) else {
                throw MCPToolError.invalidArgument(name: "captionScale", expected: String(localized: "a number from 0.8 to 1.4"))
            }
            cut.captionScale = scale
        }
        if let endCard = try arguments.optionalObject("endCard") {
            if let caption = endCard["caption"]?.boolValue { cut.endCardShowsCaption = caption }
            if let screen = endCard["screen"]?.stringValue, !screen.isEmpty { cut.endCardScreenID = try session.screen(screen).id }
        }
        return cut
    }

    /// `appPreviewTemplate` laid on the App Preview's look; nil when it
    /// isn't sent.
    @MainActor
    private static func look(_ arguments: MCPToolArguments, run: AutopilotRun, fonts: ScreenshotFontCatalog) throws -> ScreenshotTemplate? {
        guard let fields = try arguments.optionalObject("appPreviewTemplate"), let base = run.chosenDirection?.previewLook else { return nil }
        var operations = MCPDirectionTemplate.operations(from: .object(fields), over: base)
        if let ops = fields["ops"] {
            operations += try TemplateOperation.mcpOperations(from: ops, argument: "appPreviewTemplate.ops")
        }
        guard !operations.isEmpty else { return nil }
        switch TemplateOperationApplier(fonts: fonts).applying(operations, to: base) {
        case let .success(look): return look
        case let .failure(refusals): throw MCPToolError.invalidArgument(name: "appPreviewTemplate", expected: refusals.summary)
        }
    }
}
