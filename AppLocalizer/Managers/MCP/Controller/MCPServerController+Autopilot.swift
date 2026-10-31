//
//  MCPServerController+Autopilot.swift
//  AppLocalizer
//

import Foundation

/// Screenshot Autopilot's upload link: the assistant sends each capture's
/// PNG with `curl --data-binary`, then names the returned upload in
/// `report_capture`. AppLocalizer is sandboxed, so it can't read the
/// assistant's files by path. The link's secret is the run's token, which
/// only `get_capture_plan` hands out to a paired assistant.
extension MCPServerController {
    func receiveAutopilotUpload(_ request: HTTPRequest) async -> HTTPResponse {
        guard Self.isLocal(origin: request.header("origin")), Self.isLocal(host: request.header("host")) else {
            return .text(403, "Only clients on this Mac may connect.")
        }
        guard request.method == "POST" || request.method == "PUT" else { return .text(405, headers: ["Allow": "POST, PUT"]) }
        let token = String(request.path.dropFirst(MCPEndpoint.autopilotPath.count))
        guard let workspace, let center = workspace.services.screenshots.autopilot,
              !token.isEmpty, let run = center.run(uploadToken: token)
        else {
            return .json(["error": "Unknown or finished run; call get_capture_plan for the current upload link."] as JSONValue, status: 404)
        }
        guard !request.body.isEmpty else {
            return .json(["error": "The body is empty: send the PNG's bytes with curl --data-binary @file.png."] as JSONValue, status: 400)
        }
        do {
            let app = try await workspace.app(matching: run.appID)
            let file = try await workspace.services.screenshots.storeCapture(request.body, for: app)
            let upload = center.registerUpload(file, for: run)
            let result: JSONValue = [
                "upload": .string(upload.id),
                "checksum": .string(file.id),
                "pixelSize": .string(file.pixelSize.title),
            ]
            return .json(result)
        } catch {
            return .json(["error": .string(error.localizedDescription)] as JSONValue, status: 422)
        }
    }
}
