//
//  ClaudeCodeDebugStream.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Lines shaped like `claude -p --output-format stream-json --verbose`,
/// for the pretend helper's runs.
enum ClaudeCodeDebugStream {
    static let sessionID = "5d2f9a1c-7e4b-4c1a-9f3e-2b8d6a0c4e17"

    static func started(serverStatus: String = "connected") -> String {
        line([
            "type": "system",
            "subtype": "init",
            "session_id": sessionID,
            "model": "claude-opus-5-5",
            "claude_code_version": "2.1.316",
            "permissionMode": "dontAsk",
            "apiKeySource": "none",
            "mcp_servers": [["name": MCPEndpoint.serverName, "status": serverStatus]],
        ])
    }

    /// One of AppLocalizer's tools, by its own name: `get_store_page`.
    static func appLocalizer(_ tool: String, id: String) -> String {
        toolUse(ClaudeCodeToolUse.appLocalizerPrefix + tool, id: id, input: [:])
    }

    static func command(_ command: String, id: String) -> String {
        toolUse("Bash", id: id, input: ["command": command])
    }

    static func read(_ path: String, id: String) -> String {
        toolUse("Read", id: id, input: ["file_path": path])
    }

    static func said(_ text: String) -> String {
        line(["type": "assistant", "message": ["role": "assistant", "content": [["type": "text", "text": text]]]])
    }

    static func failed(_ id: String, message: String) -> String {
        line([
            "type": "user",
            "message": ["role": "user", "content": [["type": "tool_result", "tool_use_id": id, "is_error": true, "content": message]]],
        ])
    }

    /// The last line: success, or an error with what it said.
    static func result(
        isError: Bool = false,
        text: String,
        apiErrorStatus: Int? = nil,
        denials: [(tool: String, input: [String: String])] = []
    ) -> String {
        var object: [String: Any] = [
            "type": "result",
            "subtype": isError ? "error_during_execution" : "success",
            "is_error": isError,
            "result": text,
            "session_id": sessionID,
            "num_turns": 9,
            "duration_ms": 241_000,
            "permission_denials": denials.enumerated().map { index, denial in
                ["tool_name": denial.tool, "tool_use_id": "denied-\(index)", "tool_input": denial.input]
            },
        ]
        if let apiErrorStatus { object["api_error_status"] = apiErrorStatus }
        return line(object)
    }

    private static func toolUse(_ name: String, id: String, input: [String: String]) -> String {
        line(["type": "assistant", "message": ["role": "assistant", "content": [["type": "tool_use", "id": id, "name": name, "input": input]]]])
    }

    private static func line(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else { return "" }
        return String(bytes: data, encoding: .utf8) ?? ""
    }
}
#endif
