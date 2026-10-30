//
//  KeyAssistantControllerTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The API key's setup and requests, with in-memory secrets and a stub
/// vendor: Check Key, saving (and Settings → Translation using it too),
/// removing, the request log, and what's kept across launches.
@MainActor
@Suite("KeyAssistantController")
struct KeyAssistantControllerTests {
    private let secrets = InMemorySecretStore()
    private let key = "sk-ant-api03-test-key-4f2Q"

    private func controller(
        service: StubKeyAssistantService = StubKeyAssistantService(),
        defaults: UserDefaults? = nil,
        translation: TranslationPreferences? = nil
    ) -> KeyAssistantController {
        KeyAssistantController(service: service, secrets: secrets, defaults: defaults, translation: translation)
    }

    private func configuration(_ vendor: AIProviderVendor = .anthropic, translations: Bool = false) -> KeyAssistantConfiguration {
        KeyAssistantConfiguration(
            vendor: vendor,
            model: vendor.assistantModels(available: [])[0],
            keySuffix: "",
            readsReviews: true,
            usesKeyForTranslations: translations
        )
    }

    @Test func checkingAKeyGivesItsModelsOrWhyNot() async throws {
        let controller = controller(service: StubKeyAssistantService(rejectedKeys: ["sk-ant-wrong"]))
        let models = try await controller.check("  \(key)\n", vendor: .anthropic)
        #expect(models.map(\.id) == ["claude-sonnet-5-5", "claude-opus-5-5", "claude-haiku-5-5"])
        await #expect(throws: KeyAssistantKeyError.missing) { try await controller.check("  ", vendor: .anthropic) }
        await #expect(throws: KeyAssistantKeyError.rejected(.anthropic, statusCode: 401)) {
            try await controller.check("sk-ant-wrong", vendor: .anthropic)
        }
        let rejected = KeyAssistantKeyError.rejected(.anthropic, statusCode: 401)
        #expect(rejected.errorDescription == "Anthropic rejected this key (401). Check that it was copied in full.")
    }

    @Test func savingKeepsTheKeyInTheKeychainAndItsLastFour() throws {
        let controller = controller()
        try controller.save(configuration(), key: " \(key) ")
        #expect(try secrets.secret(named: "assistant.anthropic.apiKey") == key)
        #expect(controller.configuration?.keySuffix == "4f2Q")
        #expect(controller.isReady)
        #expect(controller.clientName == "Anthropic API")
        #expect(controller.summary == "Claude Sonnet 5.5 · key in the Keychain · doesn’t read code")
        #expect(controller.savedKey() == key)

        try controller.save(configuration(.gemini), key: "AIza-test-key")
        #expect(try secrets.secret(named: "assistant.anthropic.apiKey") == nil)
        #expect(try secrets.secret(named: "assistant.gemini.apiKey") == "AIza-test-key")
    }

    @Test func translationsCanUseTheSameKey() throws {
        let translation = TranslationPreferences(defaults: nil, secrets: secrets)
        let controller = controller(translation: translation)
        try controller.save(configuration(.openAI, translations: true), key: "sk-proj-test")
        #expect(translation.vendor == .openAI)
        #expect(translation.provider == .aiProvider)
        #expect(try translation.apiKey() == "sk-proj-test")

        let other = TranslationPreferences(defaults: nil, secrets: InMemorySecretStore())
        let later = KeyAssistantController(service: StubKeyAssistantService(), secrets: secrets, defaults: nil, translation: other)
        try later.save(configuration(.anthropic), key: key)
        #expect(other.provider == .appleTranslation)
        try later.setUsesKeyForTranslations(true)
        #expect(other.provider == .aiProvider)
        #expect(try other.apiKey() == key)
        #expect(later.configuration?.usesKeyForTranslations == true)
    }

    @Test func removingForgetsTheKeyButNotTranslationsCopy() throws {
        let translation = TranslationPreferences(defaults: nil, secrets: secrets)
        let controller = controller(translation: translation)
        try controller.save(configuration(translations: true), key: key)
        controller.noteRequest("Test request", tokens: 400)
        controller.remove()
        #expect(!controller.isReady)
        #expect(controller.recentRequests.isEmpty)
        #expect(try secrets.secret(named: "assistant.anthropic.apiKey") == nil)
        #expect(try translation.apiKey() == key)
    }

    @Test func theTestAsksForOneSubtitleAndLogsIt() async throws {
        let service = StubKeyAssistantService()
        let controller = controller(service: service)
        let answer = try await controller.test(key: key, vendor: .anthropic, model: AIProviderVendor.claudeModels[0], appName: "Lumen Journal")
        #expect(answer.text == "Private diary, mood & prompts")
        #expect(service.completions.first?.user.contains("Lumen Journal") == true)
        #expect(service.completions.first?.wantsJSON == false)
        #expect(controller.recentRequests.map(\.title) == ["Test request"])
        #expect(controller.recentRequests.first?.tokens == 400)
    }

    @Test func generatingNeedsASavedKeyAndSendsThePlanAsJSON() async throws {
        let service = StubKeyAssistantService(suggestions: #"{"suggestions": [{"locale": "en-US", "field": "subtitle", "value": "Calm"}]}"#)
        let controller = controller(service: service)
        let plan = KeyAssistantPlan(title: "Store Page · English (U.S.)", items: [], system: "S", user: String(repeating: "u", count: 400))
        await #expect(throws: KeyAssistantKeyError.missing) { try await controller.generate(plan) }

        try controller.save(configuration(), key: key)
        let items = try await controller.generate(plan)
        #expect(items.map(\.value) == ["Calm"])
        let sent = try #require(service.completions.last)
        #expect(sent.wantsJSON)
        #expect(sent.model == "claude-sonnet-5-5")
        #expect(sent.user == plan.user)
        #expect(controller.recentRequests.first?.title == "Store Page · English (U.S.)")
        #expect(controller.recentRequests.first?.tokens == plan.totalTokens)
    }

    @Test func recentRequestsKeepTheNewestFive() {
        let controller = controller()
        for index in 1...7 {
            controller.noteRequest("Request \(index)", tokens: index)
        }
        #expect(controller.recentRequests.map(\.title) == ["Request 7", "Request 6", "Request 5", "Request 4", "Request 3"])
    }

    @Test func theSetupIsKeptOnlyWhileTheKeyIs() throws {
        let suite = "KeyAssistantControllerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = controller(defaults: defaults)
        try first.save(configuration(), key: key)
        first.noteRequest("Test request", tokens: 400)

        let relaunched = controller(defaults: defaults)
        #expect(relaunched.configuration?.vendor == .anthropic)
        #expect(relaunched.recentRequests.map(\.title) == ["Test request"])

        try secrets.setSecret(nil, named: "assistant.anthropic.apiKey")
        #expect(controller(defaults: defaults).configuration == nil)
    }

    @Test func settingsChangesWhatRequestsInclude() {
        let controller = controller()
        try? controller.save(configuration(), key: key)
        controller.setProjectFolder(URL(filePath: ProjectFolderPath.home + "/Developer/Lumen"))
        #expect(controller.configuration?.readsProjectFolder == true)
        #expect(controller.configuration?.projectFolderPath == "~/Developer/Lumen")
        #expect(controller.summary == "Claude Sonnet 5.5 · key in the Keychain · reads commits and CHANGELOG.md, not code")
        controller.update { $0.readsReviews = false }
        #expect(controller.configuration?.readsReviews == false)
        controller.setProjectFolder(nil)
        #expect(controller.configuration?.readsProjectFolder == false)
    }

    @Test func theStatusIsReadyWithAKeyUntilAnAssistantConnects() throws {
        let clock = TestClock()
        let assistants = MCPTestFixtures.controller(clock: clock)
        let keyAssistant = controller()
        assistants.keyAssistant = keyAssistant
        #expect(assistants.assistantStatus == .notSetUp)
        try keyAssistant.save(configuration(), key: key)
        #expect(assistants.assistantStatus == .ready(client: "Anthropic API"))

        assistants.setEnabled(true)
        let paired = MCPTestFixtures.pair(.claudeCode, in: assistants, at: clock.now)
        #expect(assistants.assistantStatus == .ready(client: "Anthropic API"))
        assistants.noteSeen(paired.client.id, at: clock.now)
        #expect(assistants.assistantStatus == .connected(client: "Claude Code"))
    }
}
