//
//  MCPToolOutcome.swift
//  AppLocalizer
//

import Foundation

/// What a tool call produced: the JSON the assistant gets back, and the
/// activity log lines it leaves (one per proposed item, so a batch of prices
/// shows which were queued and which refused, and why).
struct MCPToolOutcome: Hashable, Sendable {
    var result: JSONValue
    /// Marks the result as a failure the assistant should fix and retry.
    var isError: Bool
    var logLines: [LogLine]

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

    /// The `tools/call` result: the JSON as text content.
    var callResult: JSONValue {
        let text = result.stringValue ?? result.jsonString()
        return [
            "content": [["type": "text", "text": .string(text)]],
            "isError": .bool(isError),
        ]
    }
}
