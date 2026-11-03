//
//  SetAppPreviewMusicTool.swift
//  AppLocalizer
//

import Foundation

/// `set_app_preview_music`: another library track under the App Preview,
/// at the plan or while the person watches it. No design step: AppLocalizer
/// mixes every App Preview again with it.
struct SetAppPreviewMusicTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "set_app_preview_music",
        title: "Set the App Preview's music",
        description: """
        Changes the music under the run's App Preview to one of AppLocalizer's library tracks (warm_acoustic, \
        calm_piano, bright_pop), made on this Mac and free to use on the App Store. At the plan it's the plan's \
        music; at Watch the App Preview, every App Preview is mixed again with it. Only the person can choose \
        their own file.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "track": MCPToolDefinition.string("warm_acoustic, calm_piano or bright_pop."),
                "track_id": MCPToolDefinition.string("The same as track."),
                "file": MCPToolDefinition.string("Not taken: only the person chooses their own file, which confirms they hold the rights."),
            ],
            required: ["appId"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context, atPlan: true)
        if try arguments.optionalString("file")?.isEmpty == false {
            return .refused(String(localized: """
            Only the person can choose their own file, in the plan’s Music row: choosing it confirms they \
            hold the rights.
            """), target: session.target)
        }
        guard let value = try arguments.optionalString("track") ?? arguments.optionalString("track_id") else {
            throw MCPToolError.invalidArgument(name: "track", expected: String(localized: "a library track: warm_acoustic, calm_piano or bright_pop"))
        }
        guard let track = AppPreviewTrack(rawValue: value), track.isLibrary else {
            let ids = AppPreviewTrack.library.map(\.rawValue).formatted(.list(type: .or))
            throw MCPToolError.invalidArgument(name: "track", expected: String(localized: "a library track: \(ids)"))
        }
        let run = session.run
        guard run.plan.alsoMakes.makesAppPreview else {
            return .refused(String(localized: "This run makes no App Preview."), target: session.target)
        }
        guard run.stage == .plan || run.stage == .watchPreview else {
            return .refused(String(localized: "The music can change at the plan or at Watch the App Preview."), target: session.target)
        }
        if run.stage == .watchPreview, run.previewReview?.isBusy == true {
            return .refused(String(localized: "AppLocalizer is making the App Preview again. Try in a moment."), target: session.target)
        }
        await session.center.setPreviewMusic(AutopilotPreviewMusic(track: track), appID: session.app.id, context: session.context)
        let result: JSONValue = ["status": "set", "track": .string(track.rawValue)]
        return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: "\(session.target) · \(track.title)", outcome: .proposed)])
    }
}
