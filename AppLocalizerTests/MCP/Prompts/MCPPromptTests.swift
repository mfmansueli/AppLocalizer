//
//  MCPPromptTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("MCPPrompt")
struct MCPPromptTests {
    @Test func promptsAreSlashCommandsInClaudeCode() {
        #expect(MCPPrompt.translateMissing.slashCommand == "/mcp__applocalizer__translate_missing")
        #expect(MCPPrompt.allCases.allSatisfy { $0.requiredTools.contains("list_apps") })
    }

    @Test func theListEntryTakesAnOptionalApp() {
        let json = MCPPrompt.fillAgeRating.json
        #expect(json["name"] == "fill_age_rating")
        #expect(json["arguments"]?.arrayValue?.first?["name"] == "app")
        #expect(json["arguments"]?.arrayValue?.first?["required"] == false)
    }

    @Test func theMessageNamesTheAppOrAsksToFindIt() {
        let named = MCPPrompt.translateMissing.message(app: "Lumen Journal")
        let text = named["messages"]?.arrayValue?.first?["content"]?["text"]?.stringValue ?? ""
        #expect(text.contains("the app “Lumen Journal”"))
        #expect(text.contains("propose_listing_text"))

        let unnamed = MCPPrompt.whatsNewFromGit.message(app: nil)
        let unnamedText = unnamed["messages"]?.arrayValue?.first?["content"]?["text"]?.stringValue ?? ""
        #expect(unnamedText.contains("find it with list_apps"))
        #expect(unnamed["messages"]?.arrayValue?.first?["role"] == "user")
    }

    /// App Store Connect won't create review details without a contact
    /// email, so an empty contact is part of what the assistant suggests.
    @Test(arguments: [(MCPPrompt.suggest, "info"), (.suggest, nil), (.suggestAll, nil)] as [(MCPPrompt, String?)])
    func suggestingAppInformationAsksForAnEmptyReviewContact(prompt: MCPPrompt, area: String?) {
        let text = prompt.message(app: "Alba", area: area)["messages"]?.arrayValue?.first?["content"]?["text"]?.stringValue ?? ""
        #expect(text.contains("If App Review's contact (first name, last name, phone, email) is empty"))
        #expect(text.contains("git config user.name and user.email"))
        #expect(text.contains("never make up a phone number"))
    }

    @Test func everyToolAPromptNamesIsOneItRequires() {
        for prompt in MCPPrompt.allCases {
            let text = prompt.message(app: nil)["messages"]?.arrayValue?.first?["content"]?["text"]?.stringValue ?? ""
            for tool in prompt.requiredTools {
                #expect(text.contains(tool), "\(prompt.name) doesn't mention \(tool)")
            }
        }
    }
}
