//
//  AIProviderKeyStatusTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The line under Settings → Translation's API key: what each status says,
/// and which failed checks it comes from.
@Suite("AIProviderKeyStatus")
struct AIProviderKeyStatusTests {
    @Test func everySavedStatusSaysTheKeyIsSaved() {
        let check = AIProviderKeyCheck(vendor: .anthropic, milliseconds: 182, date: .now)
        #expect(AIProviderKeyStatus.notSaved.text == nil)
        #expect(AIProviderKeyStatus.checking(.anthropic).text == "Saved · checking with Anthropic…")
        #expect(AIProviderKeyStatus.connected(check).text == "Saved · connected to Anthropic · 182 ms")
        #expect(AIProviderKeyStatus.rejected(.openAI).text == "Saved, but OpenAI rejected this key")
        #expect(AIProviderKeyStatus.unchecked(.openAI, reason: "Down.").text == "Saved · couldn’t check it with OpenAI")
    }

    @Test func aConnectedKeyIsInTheKeychainAndUsable() {
        let status = AIProviderKeyStatus.connected(AIProviderKeyCheck(vendor: .openAI, milliseconds: 90, date: .now))
        #expect(status.detail == "Kept in this Mac’s Keychain. OpenAI accepted it, so translations can use it.")
        #expect(!status.canCheckAgain)
    }

    @Test func aRejectedKeyComesFromA401Or403() {
        let status = AIProviderKeyStatus(vendor: .anthropic, error: AIProviderError.unauthorized(.anthropic))
        #expect(status == .rejected(.anthropic))
        #expect(status.canCheckAgain)
        #expect(status.detail?.contains("Paste a working key") == true)
    }

    @Test func offlineLeavesTheKeyUncheckedAndSaysSo() {
        let status = AIProviderKeyStatus(vendor: .anthropic, error: URLError(.notConnectedToInternet))
        #expect(status == .unchecked(.anthropic, reason: "You’re offline. Check again when this Mac is back online."))
        #expect(status.canCheckAgain)
    }

    @Test func otherFailuresKeepTheVendorsReason() {
        let status = AIProviderKeyStatus(vendor: .openAI, error: AIProviderError.rateLimited(.openAI))
        #expect(status == .unchecked(.openAI, reason: "OpenAI’s rate limit was reached. Try again in a minute."))
        #expect(status.detail == "OpenAI’s rate limit was reached. Try again in a minute.")
    }

    @Test func nothingToCheckAgainWhileCheckingOrWithoutAKey() {
        #expect(!AIProviderKeyStatus.notSaved.canCheckAgain)
        #expect(!AIProviderKeyStatus.checking(.anthropic).canCheckAgain)
    }
}
