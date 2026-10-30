//
//  AssistantPopoverContentTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The Assistant popover's words with an API key: where the key is and
/// what it reads, each request's size and age, and what needs an MCP
/// assistant.
@MainActor
@Suite("AssistantPopoverContent")
struct AssistantPopoverContentTests {
    @Test func theKeyLineSaysWhereItIsAndWhatItReads() {
        var key = KeyAssistantConfiguration(vendor: .anthropic, model: AIProviderVendor.claudeModels[0], keySuffix: "4f2Q")
        #expect(AssistantPopoverContent.keyPlace(key) == "Key sk-ant-…4f2Q in the Keychain")
        key.readsProjectFolder = true
        key.projectFolderPath = "~/Developer/Lumen"
        #expect(AssistantPopoverContent.keyPlace(key) == "Key sk-ant-…4f2Q in the Keychain · reads ~/Developer/Lumen’s commits")
    }

    @Test func aRequestShowsItsTokensAndAge() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let fresh = KeyAssistantRequestLog(title: "Test request", tokens: 400, date: now.addingTimeInterval(-10))
        #expect(AssistantPopoverContent.requestDetail(fresh, now: now) == "\(400.formatted()) tokens · just now")
        let older = KeyAssistantRequestLog(title: "Store Page", tokens: 9400, date: now.addingTimeInterval(-120))
        #expect(AssistantPopoverContent.requestDetail(older, now: now).hasPrefix("\(KeyAssistantTokens.formatted(9400)) tokens · "))
    }

    @Test func withAKeyWhatNeedsTheCodeNeedsAnMCPAssistant() {
        let assistant = Dictionary(uniqueKeysWithValues: AssistantPopoverContent.capabilities(withKey: false).map { ($0.title, $0.detail) })
        let key = Dictionary(uniqueKeysWithValues: AssistantPopoverContent.capabilities(withKey: true).map { ($0.title, $0.detail) })
        #expect(assistant["Age Rating"] == "Answers from what the app actually does")
        #expect(key["Age Rating"] == "Needs an MCP assistant: answers from what the app actually does")
        #expect(key["App Information"] == "Copyright and release; categories need an MCP assistant")
        #expect(key["Store Page"] == assistant["Store Page"])
        #expect(key["Screenshots"] == "Captions in every language")
    }
}
