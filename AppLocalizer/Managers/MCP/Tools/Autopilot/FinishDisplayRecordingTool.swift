//
//  FinishDisplayRecordingTool.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// `finish_display_recording`: after `start_display_recording` and a UI test
/// on iPhone Duo, each screenshot the test attached comes back as the Duo's
/// inner display just before it (`DisplayRecorder`), uploaded for
/// `report_capture`, with a small image of it for the assistant to check.
struct FinishDisplayRecordingTool: MCPTool {
    /// The images' longest side: enough to read the screen.
    static let previewSize = 1000

    let definition = MCPToolDefinition(
        name: "finish_display_recording",
        title: "Get iPhone Duo’s screenshots from the recording",
        description: """
        After start_display_recording and the UI test: stops recording and gives, for each screenshot the test \
        attached (by the name it gave it), iPhone Duo's inner display as it was just before, at full size, as an upload \
        ID, with a small image of each after the JSON, in the same order. Look at each: when it shows its screen, report \
        it with report_capture (upload, screen, displayType iphone_duo, locale, attempt, score, notes).
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "resultBundle": MCPToolDefinition.string("The absolute path of the .xcresult you passed to -resultBundlePath."),
            ],
            required: ["appId", "run", "resultBundle"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        let bundle = try (arguments.string("resultBundle") as NSString).expandingTildeInPath
        guard bundle.hasPrefix("/"), bundle.hasSuffix(".xcresult") else {
            throw MCPToolError.invalidArgument(name: "resultBundle", expected: String(localized: "the absolute path of a .xcresult bundle"))
        }
        guard let simulators = context.simulators else {
            return .refused(DisplayRecorder.Failure.notRecording.localizedDescription, target: session.target)
        }
        let shots: [DisplayRecorder.Shot]
        do {
            shots = try await simulators.recorder.finish(resultBundle: bundle)
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        guard !shots.isEmpty else {
            return .refused(String(localized: """
            The result bundle has no screenshots: the test didn’t attach any. Read its log (did it fail?), then call \
            start_display_recording and run it again.
            """), target: session.target)
        }
        var items: [JSONValue] = []
        var images: [MCPToolOutcome.ImageContent] = []
        var names: [String] = []
        for shot in shots {
            var item: [String: JSONValue] = ["name": .string(shot.pick.screenshot.name), "test": .string(shot.pick.screenshot.test)]
            if let missing = Self.missing(shot) {
                item["missing"] = .string(missing)
            } else if let png = shot.png {
                let file = try await session.context.services.storeCapture(png, for: session.app)
                item["upload"] = .string(session.center.registerUpload(file, for: session.run).id)
                item["size"] = .string("\(file.pixelSize.width) × \(file.pixelSize.height)")
                item["takenBefore"] = .string(String(format: "%.1f s before the test’s screenshot", shot.pick.lead ?? 0))
                let preview = Self.preview(png)
                if let check = Self.check(shot, preview: preview?.image) { item["check"] = .string(check) }
                if let data = preview?.data { images.append(.init(data: data, mimeType: "image/jpeg")) }
                names.append(shot.pick.screenshot.name)
            }
            items.append(.object(item))
        }
        if !names.isEmpty {
            let center = session.center
            let line = String(localized: "iPhone Duo: \(names.joined(separator: ", ")) taken from its inner display, recorded during the UI test")
            center.update(session.app.id) { $0.appendLog(line, kind: .event, at: center.now()) }
        }
        let next = String(localized: """
        Look at each image (they follow in the order above). Report each that shows its screen with report_capture and \
        its upload ID; for one that doesn't, fix what's wrong and record it again.
        """)
        return MCPToolOutcome(
            result: ["screenshots": .array(items), "next": .string(next)], isError: false,
            logLines: [.init(target: session.target, outcome: .read)], images: images
        )
    }

    /// Why a screenshot has no frame.
    private static func missing(_ shot: DisplayRecorder.Shot) -> String? {
        if shot.isOnOtherSimulator {
            return String(localized: "The test ran on another simulator than the one recorded: run it on iPhone Duo’s, as start_display_recording said.")
        }
        if shot.pick.frame == nil {
            return String(localized: "Nothing was recorded before this screenshot: call start_display_recording before running the test.")
        }
        if shot.png == nil {
            return String(localized: "AppLocalizer couldn’t read the frame: record it again.")
        }
        return nil
    }

    /// What to look at in it: a black inner display (the Duo closed), or a
    /// frame from before the screen may have been there.
    private static func check(_ shot: DisplayRecorder.Shot, preview: CGImage?) -> String? {
        if let preview, DuoInnerDisplay(preview) == .black {
            return String(localized: "The inner display is black: iPhone Duo closed. Call start_display_recording again (it opens it) and rerun the test.")
        }
        if !shot.pick.isSettled {
            return String(localized: """
            It was taken while the test was still waiting for its screen, so it may show the screen before: check it. If \
            it does, the test needs to wait a moment before its screenshot.
            """)
        }
        return nil
    }

    /// A small JPEG of the frame, and the image it's made from.
    private static func preview(_ png: Data) -> (image: CGImage, data: Data)? {
        guard let image = ScreenshotThumbnailer.thumbnail(png, maxPixelSize: previewSize) else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        return CGImageDestinationFinalize(destination) ? (image, data as Data) : nil
    }
}
