//
//  GetCaptureTool.swift
//  AppLocalizer
//

import Foundation

/// `get_capture`: one capture as an image, so the assistant can see the
/// interface it's captioning.
struct GetCaptureTool: MCPTool {
    /// Captures are sent at most this wide, to keep the result small.
    static let pixelWidth = 660

    let definition = MCPToolDefinition(
        name: "get_capture",
        title: "Get capture",
        description: """
        Returns one capture (a real screenshot of the app, from list_captures) as a PNG image, so you can see the \
        screen a caption describes. Captions should name what the screen shows.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "captureId": MCPToolDefinition.string("A captureId from list_captures."),
            ],
            required: ["appId", "captureId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let draft = try await MCPScreenshotsDraft.load(app: arguments.string("appId"), in: context.workspace)
        let capture = try draft.capture(id: arguments.string("captureId"))
        let width = min(capture.pixelSize.width, Self.pixelWidth)
        let target = draft.target(locale: capture.locale, slot: capture.slot)
        guard let image = await draft.services.captureImage(capture, for: draft.app, pixelWidth: width), let data = ScreenshotPNG.data(image) else {
            return .failed(String(localized: "Couldn’t read the capture’s image."), target: target)
        }
        let info: JSONValue = [
            "captureId": .string(capture.id),
            "locale": .string(capture.locale),
            "displayType": .string(capture.displayType.mcpValue),
            "slot": .int(capture.slot + 1),
            "fileName": .string(capture.fileName),
        ]
        return .image(data, result: info, target: target)
    }
}
