//
//  AutopilotToolboxTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The Autopilot tools as the server lists them, and the prompt Start
/// Autopilot copies.
@MainActor
@Suite("Autopilot tools in the toolbox")
struct AutopilotToolboxTests {
    private static let tools = [
        "get_capture_plan", "update_capture_plan", "report_capture", "report_capture_problem", "next_step",
        "get_design_brief", "propose_direction", "revise_direction", "report_design_source", "start_display_recording",
        "finish_display_recording", "propose_screens", "revise_app_preview", "set_app_preview_music", "answer_app_questions",
    ]

    private static var promptText: String {
        MCPPrompt.runScreenshots.message(app: "Lumen Journal")["messages"]?.arrayValue?.first?["content"]?["text"]?.stringValue ?? ""
    }

    @Test func everyAutopilotToolIsServed() {
        let toolbox = MCPToolbox.standard
        #expect(toolbox.toolNames.isSuperset(of: Self.tools))
        #expect(toolbox.tool(named: "propose_direction")?.definition.proposalKind == .screenshots)
        #expect(toolbox.tool(named: "revise_direction")?.definition.proposalKind == .screenshots)
        #expect(toolbox.tool(named: "revise_app_preview")?.definition.proposalKind == .screenshots)
        #expect(toolbox.tool(named: "set_app_preview_music")?.definition.proposalKind == .screenshots)
        // Picking a run up and reporting change state, without proposing.
        for name in [
            "get_capture_plan", "next_step", "update_capture_plan", "report_capture", "report_capture_problem", "report_design_source",
            "start_display_recording", "finish_display_recording", "propose_screens",
        ] {
            let definition = toolbox.tool(named: name)?.definition
            #expect(definition?.isReadOnly == false, "\(name)")
            #expect(definition?.proposalKind == nil, "\(name)")
            #expect(definition?.json["annotations"]?["readOnlyHint"] == false, "\(name)")
        }
        #expect(toolbox.tool(named: "get_design_brief")?.definition.isReadOnly == true)
        let required = toolbox.tool(named: "report_capture")?.definition.inputSchema["required"]?.arrayValue ?? []
        #expect(Set(required.compactMap(\.stringValue)) == ["appId", "run", "screen", "displayType", "locale", "attempt", "score", "notes"])
    }

    @Test func proposeCaptionsTakesTheRun() {
        let definition = ProposeCaptionsTool().definition
        #expect(definition.inputSchema["properties"]?["run"] != nil)
        #expect(definition.inputSchema["required"]?.arrayValue?.contains("run") == false)
        #expect(definition.description.contains("pass the run's ID as run"))
    }

    @Test func runScreenshotsIsTheAutopilotPrompt() {
        let prompt = MCPPrompt.runScreenshots
        #expect(prompt.name == "run_screenshots")
        #expect(prompt.title == "Run Screenshot Autopilot")
        #expect(prompt.slashCommand == "/mcp__applocalizer__run_screenshots")
        #expect(prompt.json["name"] == "run_screenshots")
        #expect(MCPToolbox.standard.toolNames.isSuperset(of: prompt.requiredTools))
        // Music is the person's choice; the assistant changes it only when asked.
        let optional: Set = ["report_design_source", "set_app_preview_music"]
        #expect(prompt.requiredTools.isSuperset(of: ["list_apps", "propose_captions"] + Self.tools.filter { !optional.contains($0) }))
    }

    @Test func thePromptWalksThroughEveryTool() {
        let text = Self.promptText
        #expect(text.contains("the app “Lumen Journal”"))
        for tool in Self.tools + ["list_apps", "propose_captions"] {
            #expect(text.contains(tool), "The prompt doesn't mention \(tool)")
        }
        #expect(text.contains("curl --data-binary"))
        #expect(text.contains("Never draw the interface"))
        #expect(MCPEndpoint.instructions.contains("get_capture_plan"))
        #expect(MCPEndpoint.instructions.contains("next_step"))
    }
}
