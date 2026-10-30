//
//  GenerateSuggestionsModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Generate Suggestions… on the fixture Store Page with a stub vendor: what
/// it will send, the suggestions it adds (and those it leaves out), and
/// what the toast says.
@MainActor
@Suite("Generate Suggestions with an API key")
struct GenerateSuggestionsModelTests {
    private let app = StorePageContentFixtures.app
    private let store = FieldSuggestionStore()
    private let secrets = InMemorySecretStore()
    private let services = FakeStorePageServices()

    private func generating(_ answer: String, readsReviews: Bool = false) async throws -> (GenerateSuggestionsModel, StorePageViewModel) {
        let keyAssistant = KeyAssistantController(service: StubKeyAssistantService(suggestions: answer), secrets: secrets, defaults: nil)
        try keyAssistant.save(
            KeyAssistantConfiguration(vendor: .anthropic, model: AIProviderVendor.claudeModels[0], keySuffix: "", readsReviews: readsReviews),
            key: "sk-ant-api03-test-key-4f2Q"
        )
        let page = StorePageViewModel(app: app, services: services, queue: ChangeQueue(), suggestions: store)
        await page.load()
        let model = GenerateSuggestionsModel(keyAssistant: keyAssistant, generator: page, suggestions: store, appID: app.id, area: .storePage)
        await model.prepare()
        return (model, page)
    }

    private static func answer(_ items: [(String, String, String)]) -> String {
        let list = items.map { #"{"locale": "\#($0.0)", "field": "\#($0.1)", "value": "\#($0.2)", "reason": "From the commits."}"# }
        return #"{"suggestions": [\#(list.joined(separator: ","))]}"#
    }

    @Test func showsWhatItWillSendFirst() async throws {
        services.reviews = [CustomerReview(rating: 5, title: "Calm", body: "Private.")]
        let (model, _) = try await generating(Self.answer([]), readsReviews: true)
        #expect(model.phase == .ready)
        #expect(model.title == "Generate with Anthropic API")
        #expect(model.intro == "AppLocalizer sends this to Anthropic, then shows the suggestions here. Nothing changes until you accept them.")
        #expect(model.plan?.items.map(\.id) == ["store", "reviews"])
        #expect(model.totalText?.hasPrefix("About ") == true)
        #expect(model.canGenerate)
    }

    @Test func reviewsThatCantBeReadAreANote() async throws {
        services.reviewsError = URLError(.notConnectedToInternet)
        let (model, _) = try await generating(Self.answer([]), readsReviews: true)
        #expect(model.plan?.items.map(\.id) == ["store"])
        #expect(model.plan?.notes.first?.hasPrefix("Reviews couldn’t be read, so they aren’t sent:") == true)
    }

    @Test func addsTheSuggestionsThatPassAsACompleteRequest() async throws {
        let answer = Self.answer([
            ("en-US", "whatsNew", "• Weekly reflections"),
            ("de-DE", "promotionalText", "Neu: Wochenrückblick."),
            ("en-US", "subtitle", "Private notes, gentle prompts"),
            ("en-US", "subtitle", String(repeating: "x", count: 31)),
            ("fr-FR", "whatsNew", "Nouveau"),
            ("en-US", "description", "Longer."),
            ("en-US", "colour", "Blue"),
        ])
        let (model, page) = try await generating(answer)
        #expect(await model.generate() == .sent)
        #expect(page.shownSuggestion(.whatsNew, in: .englishUS)?.source == .assistant(client: "Anthropic API"))
        #expect(page.shownSuggestion(.whatsNew, in: .englishUS)?.reason == "From the commits.")
        #expect(page.shownSuggestion(.promotionalText, in: .german)?.value == "Neu: Wochenrückblick.")
        #expect(store.open(for: app.id, filter: .assistant).count == 2)
        let request = try #require(store.request)
        #expect(request.client == "Anthropic API")
        #expect(request.received == 2)
        #expect(request.isComplete)
        #expect(request.finishedText == "Anthropic API sent 2 suggestions. Nothing changes until you accept them.")
    }

    @Test func nothingNewEndsWithItsOwnToast() async throws {
        let (model, _) = try await generating(Self.answer([("en-US", "subtitle", "Private notes, gentle prompts")]))
        #expect(await model.generate() == .nothingNew("Anthropic API found nothing new to suggest."))
        #expect(store.request == nil)
        #expect(model.phase == .ready)
    }

    @Test func anUnreadableAnswerStaysOpenWithWhy() async throws {
        let (model, _) = try await generating("I can’t help with that.")
        #expect(await model.generate() == .failed)
        #expect(model.phase == .failed(AIProviderError.unreadableResponse(.anthropic).localizedDescription))
        #expect(model.canGenerate)
        #expect(store.request == nil)
    }
}
