//
//  InAppTextsAskPromptTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// "Ask Claude Code…" on In-App Texts: the prompt names the app and the
/// two tools, and the run has its own purpose.
@Suite("InAppTextsAskPrompt")
struct InAppTextsAskPromptTests {
    @Test func thePromptNamesTheAppAndItsTools() {
        let prompt = InAppTextsAskPrompt.text(app: "Alba: Daily Motivation")
        #expect(prompt.contains("Alba: Daily Motivation"))
        #expect(prompt.contains("get_in_app_texts"))
        #expect(prompt.contains("propose_in_app_texts"))
    }

    @Test func itsRunIsAnAskOfItsOwn() {
        #expect(InAppTextsAskPrompt.purpose == .ask(area: "In-App Texts"))
        #expect(InAppTextsAskPrompt.purpose.permissions == .readProject)
    }
}
