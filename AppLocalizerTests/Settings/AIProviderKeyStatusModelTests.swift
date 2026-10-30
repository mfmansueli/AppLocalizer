//
//  AIProviderKeyStatusModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Settings → Translation checking the saved API key: only with a key, for
/// the selected vendor, and never overwritten by a check that was
/// cancelled.
@MainActor
@Suite("AIProviderKeyStatusModel")
struct AIProviderKeyStatusModelTests {
    private func make(secrets: [String: String] = [:]) -> (AIProviderKeyStatusModel, FakeAIProviderKeyChecker, TranslationPreferences) {
        let checker = FakeAIProviderKeyChecker()
        let preferences = TranslationPreferences(defaults: nil, secrets: InMemorySecretStore(secrets: secrets))
        return (AIProviderKeyStatusModel(checker: checker), checker, preferences)
    }

    @Test func withoutAKeyNothingIsSent() async {
        let (model, checker, preferences) = make()
        await model.check(preferences)
        #expect(model.status == .notSaved)
        #expect(checker.checkedKeys.isEmpty)
    }

    @Test func aSavedKeyThatWorksIsConnected() async throws {
        let (model, checker, preferences) = make()
        try preferences.saveAPIKey("sk-ant-123")
        await model.check(preferences)
        #expect(model.status == .connected(AIProviderKeyCheck(vendor: .anthropic, milliseconds: 182, date: FakeAIProviderKeyChecker.checkedAt)))
        #expect(checker.checkedKeys == ["sk-ant-123"])
        #expect(checker.checkedVendors == [.anthropic])
    }

    @Test func aKeyTheVendorRefusesIsRejected() async {
        let (model, checker, preferences) = make(secrets: [AIProviderVendor.anthropic.secretName: "sk-ant-old"])
        checker.error = AIProviderError.unauthorized(.anthropic)
        await model.check(preferences)
        #expect(model.status == .rejected(.anthropic))
    }

    @Test func switchingVendorChecksThatVendorsKey() async {
        let (model, checker, preferences) = make(secrets: [AIProviderVendor.anthropic.secretName: "sk-ant-123"])
        await model.check(preferences)
        preferences.vendor = .openAI
        await model.check(preferences)
        // OpenAI has no key saved: the Anthropic status doesn't carry over.
        #expect(model.status == .notSaved)
        #expect(checker.checkedKeys.count == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func aCancelledCheckLeavesTheStatusToTheNextOne() async {
        let (model, checker, preferences) = make(secrets: [AIProviderVendor.openAI.secretName: "sk-123"])
        preferences.vendor = .openAI
        checker.waitsForCancellation = true
        let running = Task { await model.check(preferences) }
        while checker.checkedKeys.isEmpty {
            await Task.yield()
        }
        #expect(model.status == .checking(.openAI))
        running.cancel()
        await running.value
        #expect(model.status == .checking(.openAI))
    }
}
