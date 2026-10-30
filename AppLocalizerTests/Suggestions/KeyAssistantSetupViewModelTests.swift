//
//  KeyAssistantSetupViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The setup sheet with an API key: Check Key and its answer, the model,
/// the test request, and saving only at the end; then the same sheet
/// opened again on the saved key.
@MainActor
@Suite("KeyAssistantSetupViewModel")
struct KeyAssistantSetupViewModelTests {
    private let secrets = InMemorySecretStore()
    private let key = "sk-ant-api03-test-key-4f2Q"

    private func controller(_ service: StubKeyAssistantService = StubKeyAssistantService(rejectedKeys: ["sk-ant-short"])) -> KeyAssistantController {
        KeyAssistantController(service: service, secrets: secrets, defaults: nil, translation: TranslationPreferences(defaults: nil, secrets: secrets))
    }

    private func setup(_ controller: KeyAssistantController) -> AssistantSetupViewModel {
        AssistantSetupViewModel(assistants: MCPTestFixtures.controller(clock: TestClock()), keyAssistant: controller, appName: "Lumen Journal", method: .apiKey)
    }

    @Test func checkingTheKeyOffersItsModels() async {
        let setup = KeyAssistantSetupViewModel(controller: controller(), appName: "Lumen Journal")
        #expect(setup.keyPlaceholder == "sk-ant-api03-…")
        setup.key = "sk-ant-short"
        await setup.checkKey()
        #expect(setup.keyState == .rejected("Anthropic rejected this key (401). Check that it was copied in full."))

        setup.key = key
        #expect(setup.keyState == .idle)
        await setup.checkKey()
        #expect(setup.keyState == .works("Key works · 3 models available"))
        #expect(setup.model?.id == "claude-sonnet-5-5")

        setup.vendor = .gemini
        #expect(setup.keyState == .idle)
        #expect(setup.models.isEmpty)
        #expect(setup.keyFacts.first?.text == "Stored in the Keychain on this Mac. Sent only to Google Gemini, with each request.")
    }

    @Test func theStepsCheckTestAndSaveAtTheEnd() async {
        let keyAssistant = controller()
        let setup = setup(keyAssistant)
        #expect(setup.stepTitles == AssistantSetupMethod.apiKey.stepTitles)
        #expect(setup.footnote == "You can add the other way later in Settings → AI Assistants.")
        #expect(!setup.advance())
        #expect(setup.step == .server)
        #expect(!setup.canContinue)
        #expect(setup.footnote == "The key only ever goes to Anthropic.")

        setup.key.key = key
        await setup.key.checkKey()
        #expect(setup.canContinue)
        #expect(!setup.advance())
        #expect(setup.step == .snippet)
        #expect(!setup.advance())
        #expect(setup.step == .test)
        #expect(!keyAssistant.isReady)

        await setup.key.runTest()
        #expect(setup.key.testState == .works("Claude Sonnet 5.5 answered in \(2.1.formatted(.number.precision(.fractionLength(1)))) s with a subtitle: “Private diary, mood & prompts”."))
        #expect(setup.continueTitle == "Done")
        #expect(setup.advance())
        #expect(keyAssistant.configuration?.model.id == "claude-sonnet-5-5")
        #expect(keyAssistant.configuration?.readsReviews == true)
        #expect(keyAssistant.configuration?.usesKeyForTranslations == true)
        #expect(setup.finishedAnnouncement == "Anthropic API is ready. Use Generate Suggestions on Store Page.")
    }

    @Test func cancellingSavesNothing() async throws {
        let keyAssistant = controller()
        let setup = setup(keyAssistant)
        _ = setup.advance()
        setup.key.key = key
        await setup.key.checkKey()
        setup.cancel()
        #expect(!keyAssistant.isReady)
        #expect(try secrets.secret(named: "assistant.anthropic.apiKey") == nil)
    }

    @Test func aFailedTestCanStillFinish() async {
        let setup = setup(controller())
        _ = setup.advance()
        setup.key.key = key
        await setup.key.checkKey()
        _ = setup.advance()
        _ = setup.advance()
        #expect(setup.continueTitle == "Finish Without Testing")
        #expect(setup.canGoBack)
    }

    @Test func reopeningShowsTheSavedKey() throws {
        let keyAssistant = controller()
        var configuration = KeyAssistantConfiguration(vendor: .anthropic, model: AIProviderVendor.claudeModels[2], keySuffix: "")
        configuration.readsReviews = false
        try keyAssistant.save(configuration, key: key)
        let setup = KeyAssistantSetupViewModel(controller: keyAssistant, appName: "Lumen Journal")
        #expect(setup.key == key)
        #expect(setup.model?.id == "claude-haiku-5-5")
        #expect(setup.keyState.isWorking)
        #expect(!setup.readsReviews)
    }
}
