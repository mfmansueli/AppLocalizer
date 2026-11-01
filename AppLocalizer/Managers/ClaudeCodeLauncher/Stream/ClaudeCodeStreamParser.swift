//
//  ClaudeCodeStreamParser.swift
//  AppLocalizer
//

import Foundation

/// Reads `claude -p --output-format stream-json --verbose` one line at a
/// time. Unknown line types and fields are skipped, so a newer Claude Code
/// that adds some still works; a line that isn't JSON (the helper's own
/// last line) parses to nothing.
enum ClaudeCodeStreamParser {
    static func events(in line: String) -> [ClaudeCodeStreamEvent] {
        guard line.hasPrefix("{"), let data = line.data(using: .utf8),
              let json = try? JSONDecoder().decode(JSONValue.self, from: data) else { return [] }
        switch json["type"]?.stringValue {
        case "system":
            return started(json).map { [$0] } ?? []
        case "assistant":
            return assistantEvents(json["message"]?["content"]?.arrayValue ?? [])
        case "user":
            return failedTools(json["message"]?["content"]?.arrayValue ?? [])
        case "result":
            return [.finished(result(json))]
        default:
            return []
        }
    }

    private static func started(_ json: JSONValue) -> ClaudeCodeStreamEvent? {
        guard json["subtype"]?.stringValue == "init", let sessionID = json["session_id"]?.stringValue else { return nil }
        let failed = (json["mcp_servers"]?.arrayValue ?? []).compactMap { server -> String? in
            guard let name = server["name"]?.stringValue, let status = server["status"]?.stringValue, status != "connected" else { return nil }
            return name
        }
        return .started(
            sessionID: sessionID,
            model: json["model"]?.stringValue,
            version: json["claude_code_version"]?.stringValue,
            failedServers: failed
        )
    }

    private static func assistantEvents(_ content: [JSONValue]) -> [ClaudeCodeStreamEvent] {
        content.compactMap { block in
            switch block["type"]?.stringValue {
            case "text":
                guard let text = block["text"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
                return .said(text)
            case "tool_use":
                guard let id = block["id"]?.stringValue, let name = block["name"]?.stringValue else { return nil }
                return .usedTool(ClaudeCodeToolUse(id: id, name: name, input: block["input"]))
            default:
                return nil
            }
        }
    }

    private static func failedTools(_ content: [JSONValue]) -> [ClaudeCodeStreamEvent] {
        content.compactMap { block in
            guard block["type"]?.stringValue == "tool_result", block["is_error"]?.boolValue == true,
                  let id = block["tool_use_id"]?.stringValue else { return nil }
            return .toolFailed(toolUseID: id, message: text(of: block["content"]))
        }
    }

    /// A tool result's content: a string, or text blocks.
    private static func text(of content: JSONValue?) -> String {
        if let string = content?.stringValue { return string.trimmingCharacters(in: .whitespacesAndNewlines) }
        let parts = (content?.arrayValue ?? []).compactMap { $0["text"]?.stringValue }
        return parts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func result(_ json: JSONValue) -> ClaudeCodeResult {
        let denials = (json["permission_denials"]?.arrayValue ?? []).compactMap { denial -> ClaudeCodeResult.Denial? in
            guard let name = denial["tool_name"]?.stringValue else { return nil }
            let (_, summary) = ClaudeCodeToolUse.describe(name: name, input: denial["tool_input"])
            return ClaudeCodeResult.Denial(toolName: name, summary: summary)
        }
        let isError = json["is_error"]?.boolValue ?? (json["subtype"]?.stringValue != "success")
        return ClaudeCodeResult(
            isError: isError,
            text: (json["result"]?.stringValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            sessionID: json["session_id"]?.stringValue,
            subtype: json["subtype"]?.stringValue,
            turns: json["num_turns"]?.intValue,
            duration: json["duration_ms"]?.intValue.map { .milliseconds($0) },
            apiErrorStatus: json["api_error_status"]?.intValue,
            denials: denials
        )
    }
}
