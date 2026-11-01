//
//  ClaudeCodeTestFixtures.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Launchers over an in-memory MCP server and a pretend helper, and the
/// stream lines Claude Code prints.
enum ClaudeCodeTestFixtures {
    static let helperURL = URL(fileURLWithPath: "/Users/sam/Library/Application Scripts/com.lima.applocalizer/Start Claude Code.zsh")
    static let lumenID: StoreApp.ID = "6450000001"
    static let tempoID: StoreApp.ID = "6450000003"
    static let lumenFolder = "/Users/sam/Developer/Lumen"

    /// A launcher whose Open panel answers `chosenFolder` (nil: cancelled),
    /// recording what it was asked.
    @MainActor
    static func launcher(
        assistants: MCPServerController,
        runner: FakeUnixScriptRunner = FakeUnixScriptRunner(),
        defaults: UserDefaults? = nil,
        clock: TestClock = TestClock(),
        chosenFolder: String? = lumenFolder,
        asked: FolderRequests = FolderRequests()
    ) -> ClaudeCodeLauncher {
        ClaudeCodeLauncher(
            assistants: assistants,
            runner: runner,
            helperURL: helperURL,
            defaults: defaults,
            now: { clock.now },
            folderChooser: { appName, suggestion in
                asked.requests.append((appName, suggestion))
                return chosenFolder
            }
        )
    }

    /// What the Open panel was asked: the app's name and the suggested
    /// folder.
    final class FolderRequests {
        var requests: [(appName: String, suggestion: String?)] = []
    }

    /// Waits for the run's task to reach the helper.
    @MainActor
    static func waitForHelper(_ runner: FakeUnixScriptRunner, runs count: Int = 1) async {
        await MCPTestFixtures.waitUntil { runner.recordedArguments.filter { $0.first == "run" }.count >= count }
    }

    /// Waits for a run to end.
    @MainActor
    static func waitForEnd(of id: ClaudeCodeRun.ID?, in launcher: ClaudeCodeLauncher) async {
        await MCPTestFixtures.waitUntil { launcher.run(id)?.isActive == false }
    }

    // MARK: - Stream lines, as Claude Code 2.1.316 prints them

    static let sessionID = "8c1e2f4a-3b5d-4e6f-9a0b-1c2d3e4f5a6b"

    static func initLine(serverStatus: String = "connected") -> String {
        """
        {"type":"system","subtype":"init","cwd":"/Users/sam/Developer/Lumen","session_id":"\(sessionID)",\
        "tools":["Read","Grep","Glob","Bash","mcp__applocalizer__list_apps"],\
        "mcp_servers":[{"name":"applocalizer","status":"\(serverStatus)"}],"model":"claude-opus-5-5",\
        "permissionMode":"dontAsk","apiKeySource":"none","claude_code_version":"2.1.316","uuid":"0b9f"}
        """
    }

    static func toolUseLine(_ name: String, id: String, input: String = "{}") -> String {
        """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"\(id)","name":"\(name)",\
        "input":\(input)}]},"session_id":"\(sessionID)"}
        """
    }

    static func saidLine(_ text: String) -> String {
        """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"\(text)"}]},"session_id":"\(sessionID)"}
        """
    }

    static func toolErrorLine(_ id: String, message: String) -> String {
        """
        {"type":"user","message":{"role":"user","content":[{"tool_use_id":"\(id)","type":"tool_result",\
        "content":"\(message)","is_error":true}]},"session_id":"\(sessionID)"}
        """
    }

    static func resultLine(
        isError: Bool = false,
        text: String,
        apiErrorStatus: String = "null",
        denials: String = "[]"
    ) -> String {
        """
        {"type":"result","subtype":"\(isError ? "error_during_execution" : "success")","is_error":\(isError),\
        "duration_ms":8123,"num_turns":3,"result":"\(text)","session_id":"\(sessionID)",\
        "api_error_status":\(apiErrorStatus),"permission_denials":\(denials)}
        """
    }
}
