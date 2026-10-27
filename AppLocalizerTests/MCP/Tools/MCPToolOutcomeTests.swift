//
//  MCPToolOutcomeTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("MCP tool results")
struct MCPToolOutcomeTests {
    @Test func readsReturnTheirJSONAsText() {
        let outcome = MCPToolOutcome.read(["appId": "1", "name": "Lumen"], target: "Lumen")
        #expect(!outcome.isError)
        #expect(outcome.callResult == ["content": [["type": "text", "text": #"{"appId":"1","name":"Lumen"}"#]], "isError": false])
        #expect(outcome.logLines == [.init(target: "Lumen", outcome: .read)])
    }

    @Test func proposalsAreQueuedOrRefusedWithAReason() {
        let queued = MCPToolOutcome.queued(changeID: "listing.de-DE.subtitle", target: "Lumen · de-DE · Subtitle")
        #expect(queued.result == ["status": "queued", "changeId": "listing.de-DE.subtitle"])
        #expect(queued.logLines.first?.outcome == .proposed)

        let refused = MCPToolOutcome.refused("34 characters; the limit is 30.", target: "Lumen · de-DE · Subtitle", details: ["limit": 30])
        #expect(!refused.isError)
        #expect(refused.result == ["status": "refused", "reason": "34 characters; the limit is 30.", "limit": 30])
        #expect(refused.logLines.first?.reason == "34 characters; the limit is 30.")
    }

    @Test func failuresAreErrorsWithPlainText() {
        let failed = MCPToolOutcome.failed("AppLocalizer isn’t connected.", target: "")
        #expect(failed.isError)
        #expect(failed.callResult["content"]?.arrayValue?.first?["text"] == "AppLocalizer isn’t connected.")
        #expect(failed.logLines.first?.outcome == .refused)
    }

    @Test func definitionsDescribeToolsForAssistants() {
        let read = MCPToolDefinition(name: "get_listing", title: "Get listing", description: "Reads.", inputSchema: MCPToolDefinition.schema(
            ["appId": MCPToolDefinition.string("The app.")],
            required: ["appId"]
        ))
        #expect(read.isReadOnly)
        #expect(read.json["annotations"]?["readOnlyHint"] == true)
        #expect(read.json["annotations"]?["destructiveHint"] == false)
        #expect(read.json["inputSchema"]?["required"] == ["appId"])
        #expect(read.json["inputSchema"]?["additionalProperties"] == false)
        #expect(read.json["inputSchema"]?["properties"]?["appId"]?["type"] == "string")

        var proposal = read
        proposal.proposalKind = .storeText
        #expect(!proposal.isReadOnly)
        #expect(proposal.json["annotations"]?["readOnlyHint"] == false)
    }
}
