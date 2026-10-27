//
//  MCPBridgeMessage.swift
//  applocalizer-mcp
//

import Foundation

/// One JSON-RPC message an MCP client wrote to stdin, read only as far as the
/// bridge needs: its method, and its id so a failure can answer it.
struct MCPBridgeMessage: Sendable {
    /// The line's bytes, posted as they are.
    let body: Data
    let method: String?
    /// The id as JSON text, e.g. `7` or `"a1"`; nil for notifications and
    /// responses to the server.
    let idJSON: String?

    /// nil when the line isn't a JSON object.
    init?(line: String) {
        let body = Data(line.utf8)
        guard let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { return nil }
        self.body = body
        method = object["method"] as? String
        idJSON = object["id"].flatMap { id in
            (try? JSONSerialization.data(withJSONObject: id, options: [.fragmentsAllowed])).flatMap { String(data: $0, encoding: .utf8) }
        }
    }

    /// A request waits for an answer, so failures are reported to it.
    var isRequest: Bool { method != nil && idJSON != nil }

    var isInitialize: Bool { method == "initialize" }

    /// A JSON-RPC error answering `idJSON` (or `null`), as one line.
    static func error(id idJSON: String?, code: Int, message: String) -> String {
        let message = (try? JSONEncoder().encode(message)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
        return #"{"jsonrpc":"2.0","id":\#(idJSON ?? "null"),"error":{"code":\#(code),"message":\#(message)}}"#
    }
}
