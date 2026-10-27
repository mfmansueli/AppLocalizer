//
//  ScreenshotToolboxTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The screenshot tools and prompts as the server lists them.
@MainActor
@Suite("Screenshot tools in the toolbox")
struct ScreenshotToolboxTests {
    private static let readTools = [
        "get_screenshot_context", "list_captures", "get_capture", "get_template", "get_captions", "measure_caption",
        "render_preview", "list_proposals",
    ]

    @Test func everyScreenshotToolIsServed() {
        let names = MCPToolbox.standard.toolNames
        #expect(names.isSuperset(of: Self.readTools + ["propose_template", "propose_captions"]))
        for name in Self.readTools {
            #expect(MCPToolbox.standard.tool(named: name)?.definition.isReadOnly == true, "\(name)")
        }
        #expect(MCPToolbox.standard.tool(named: "propose_template")?.definition.proposalKind == .screenshots)
        #expect(MCPToolbox.standard.tool(named: "propose_captions")?.definition.proposalKind == .screenshots)
    }

    @Test func theTranslateSheetCopiesTheCaptionsPrompt() {
        #expect(MCPPrompt.translateCaptions.name == CaptionAssistantPrompt.promptName)
        #expect(MCPPrompt(rawValue: CaptionAssistantPrompt.promptName) == .translateCaptions)
    }

    @Test func screenshotPromptsNeedOnlyServedTools() {
        let names = MCPToolbox.standard.toolNames
        for prompt in [MCPPrompt.translateCaptions, .shortenOverflowingCaptions, .reviseTemplate] {
            #expect(names.isSuperset(of: prompt.requiredTools), "\(prompt.name)")
        }
        #expect(MCPPrompt.reviseTemplate.requiredTools.contains("propose_template"))
        #expect(MCPPrompt.shortenOverflowingCaptions.requiredTools.contains("measure_caption"))
    }

    @Test func imagesFollowTheJSONInTheCallResult() {
        let outcome = MCPToolOutcome.image(Data([1, 2, 3]), result: ["slot": 1], target: "Lumen Journal · de-DE · slot 1")
        #expect(outcome.callResult == [
            "content": [
                ["type": "text", "text": #"{"slot":1}"#],
                ["type": "image", "data": "AQID", "mimeType": "image/png"],
            ],
            "isError": false,
        ])
        #expect(outcome.logLines == [.init(target: "Lumen Journal · de-DE · slot 1", outcome: .read)])
    }
}
