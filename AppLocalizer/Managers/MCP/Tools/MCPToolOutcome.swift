//
//  MCPToolOutcome.swift
//  AppLocalizer
//

import Foundation

/// What a tool call produced: the JSON the assistant gets back, any
/// images with it, and the activity log lines it leaves (one per proposed
/// item, so a batch of prices shows which were queued and which refused,
/// and why).
struct MCPToolOutcome: Hashable, Sendable {
    var result: JSONValue
    /// Marks the result as a failure the assistant should fix and retry.
    var isError: Bool
    var logLines: [LogLine]
    /// Images after the JSON, e.g. a capture or a rendered preview.
    var images: [ImageContent] = []

    /// An image as MCP image content.
    struct ImageContent: Hashable, Sendable {
        var data: Data
        var mimeType: String

        /// `{type: "image", data: <base64>, mimeType}`.
        var json: JSONValue {
            ["type": "image", "data": .string(data.base64EncodedString()), "mimeType": .string(mimeType)]
        }
    }

    struct LogLine: Hashable, Sendable {
        /// What the call was about, e.g. "Lumen Journal · ko · Description".
        var target: String
        var outcome: MCPCallOutcome
        var reason: String?
    }

    /// A read that returned `result`.
    static func read(_ result: JSONValue, target: String) -> MCPToolOutcome {
        MCPToolOutcome(result: result, isError: false, logLines: [LogLine(target: target, outcome: .read)])
    }

    /// A read that returned an image, described by `result`.
    static func image(_ data: Data, mimeType: String = "image/png", result: JSONValue, target: String) -> MCPToolOutcome {
        MCPToolOutcome(
            result: result, isError: false, logLines: [LogLine(target: target, outcome: .read)],
            images: [ImageContent(data: data, mimeType: mimeType)]
        )
    }

    /// One proposal queued for review as change `changeID`.
    static func queued(changeID: String, target: String) -> MCPToolOutcome {
        MCPToolOutcome(
            result: ["status": "queued", "changeId": .string(changeID)],
            isError: false,
            logLines: [LogLine(target: target, outcome: .proposed)]
        )
    }

    /// A proposal that wasn't queued. It isn't an error: the assistant reads
    /// `reason` and proposes again.
    static func refused(_ reason: String, target: String, details: [String: JSONValue] = [:]) -> MCPToolOutcome {
        var result = details
        result["status"] = "refused"
        result["reason"] = .string(reason)
        return MCPToolOutcome(result: .object(result), isError: false, logLines: [LogLine(target: target, outcome: .refused, reason: reason)])
    }

    /// A call that couldn't run at all (a missing argument, nothing to act
    /// on, a failed request to App Store Connect).
    static func failed(_ message: String, target: String) -> MCPToolOutcome {
        MCPToolOutcome(result: .string(message), isError: true, logLines: [LogLine(target: target, outcome: .refused, reason: message)])
    }

    /// The `tools/call` result: the JSON as text content, then the images.
    var callResult: JSONValue {
        let text = result.stringValue ?? result.jsonString()
        let content: [JSONValue] = [["type": "text", "text": .string(text)]] + images.map(\.json)
        return [
            "content": .array(content),
            "isError": .bool(isError),
        ]
    }
}
