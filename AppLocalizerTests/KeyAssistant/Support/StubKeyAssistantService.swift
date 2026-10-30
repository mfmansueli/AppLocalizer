//
//  StubKeyAssistantService.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// Answers like a vendor without waiting, and records each completion:
/// `rejectedKeys` get a 401, the test request answers `testAnswer`, and a
/// JSON request answers `suggestions`.
final class StubKeyAssistantService: KeyAssistantService {
    private let state = Mutex<[AIProviderCompletion]>([])
    let models: [String]
    let rejectedKeys: Set<String>
    let testAnswer: String
    let suggestions: String

    init(
        models: [String] = ["claude-sonnet-5-5", "claude-opus-5-5", "claude-haiku-5-5"],
        rejectedKeys: Set<String> = [],
        testAnswer: String = "“Private diary, mood & prompts”",
        suggestions: String = #"{"suggestions": []}"#
    ) {
        self.models = models
        self.rejectedKeys = rejectedKeys
        self.testAnswer = testAnswer
        self.suggestions = suggestions
    }

    var completions: [AIProviderCompletion] { state.withLock { $0 } }

    func modelIDs(vendor: AIProviderVendor, apiKey: String) async throws -> [String] {
        if rejectedKeys.contains(apiKey) { throw KeyAssistantKeyError.rejected(vendor, statusCode: 401) }
        return models
    }

    func complete(_ completion: AIProviderCompletion, vendor _: AIProviderVendor, apiKey _: String) async throws -> KeyAssistantAnswer {
        state.withLock { $0.append(completion) }
        let text = completion.wantsJSON ? suggestions : testAnswer
        return KeyAssistantAnswer(text: text, tokens: completion.wantsJSON ? nil : 400, duration: .milliseconds(2100))
    }
}
