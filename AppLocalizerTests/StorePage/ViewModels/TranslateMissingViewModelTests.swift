//
//  TranslateMissingViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
import Testing
@testable import AppLocalizer

/// "Translate Missing…" with a fake translator: what's planned, what runs,
/// and what the suggestions turn into.
@MainActor
@Suite("TranslateMissingViewModel")
struct TranslateMissingViewModelTests {
    private let app = StorePageContentFixtures.app

    private func makeModel(translator: FakeListingTranslator = FakeListingTranslator(), queue: ChangeQueue = ChangeQueue()) async -> StorePageViewModel {
        let model = StorePageViewModel(app: app, services: FakeStorePageServices(translator: translator), queue: queue)
        await model.load()
        return model
    }

    private func runToSuggestions(_ model: StorePageViewModel) async {
        model.startTranslation()
        await model.translation.waitUntilFinished()
    }

    // MARK: - The sheet

    @Test func plansEveryMissingFieldCopyingURLs() async {
        let model = await makeModel()
        model.presentTranslate()
        let plan = model.translation.plan
        #expect(model.sheet == .translate)
        #expect(plan.locales == [.german])
        #expect(plan.totalCount == 6)
        #expect(plan.items.filter { $0.method == .copy }.map(\.key.field) == [.privacyPolicyURL, .supportURL, .marketingURL])
        #expect(model.translation.startTitle == "Translate 6 Fields")
        #expect(plan.summary == "6 empty fields in 1 locale. URLs are copied from English (U.S.), not translated.")
    }

    @Test func aFieldScopeNarrowsThePlan() async {
        let model = await makeModel()
        model.presentTranslate()
        model.translation.field = .keywords
        #expect(model.translation.selectedPlan.items.map(\.key) == [ListingFieldKey(.german, .keywords)])
    }

    @Test func uncheckingALocaleLeavesItOut() async {
        let model = await makeModel()
        model.addLocale(.french)
        model.presentTranslate()
        model.translation.setIncluded(.german, false)
        #expect(!model.translation.isIncluded(.german))
        #expect(Set(model.translation.selectedPlan.locales) == [.french])
    }

    @Test func providersThatNeedSetupCantStart() async {
        let model = await makeModel()
        model.presentTranslate()
        #expect(model.translation.canStart)
        model.translation.provider = .aiProvider
        #expect(!model.translation.canStart)
        model.translation.provider = .assistant
        #expect(!model.translation.canStart)
        #expect(TranslationProvider.assistant.setupMessage != nil)
    }

    @Test func theAIProviderStartsOnceItsKeyIsSaved() async {
        let model = await makeModel()
        model.presentTranslate()
        model.translation.provider = .aiProvider
        #expect(model.translation.setupMessage == "Add an AI provider and its API key in Settings → Translation first.")
        model.translation.aiProvider = AIProviderSetup(vendor: .anthropic, hasKey: true) { _ in FakeListingTranslator() }
        #expect(model.translation.setupMessage == nil)
        #expect(model.translation.canStart)
    }

    @Test func settingsChooseTheProviderAndAddTheirTerms() async {
        let model = await makeModel()
        model.presentTranslate()
        let settings = TranslationGlossary(terms: ["Face ID"], tone: .professional)
        model.translation.applySettings(provider: .assistant, glossary: settings, aiProvider: .none)
        #expect(model.translation.provider == .assistant)
        #expect(model.translation.glossary.terms == ["Face ID", "Lumen Journal"])
        #expect(model.translation.glossary.tone == .professional)
    }

    @Test func aProviderPickedBeforeTheSheetAppearsStays() async {
        let model = await makeModel()
        model.presentTranslate()
        model.translation.provider = .assistant
        model.translation.applySettings(provider: .appleTranslation, glossary: TranslationGlossary(), aiProvider: .none)
        #expect(model.translation.provider == .assistant)
    }

    @Test func theGlossaryStartsWithTheAppsName() async {
        let model = await makeModel()
        model.presentTranslate()
        #expect(model.translation.glossary.terms == ["Lumen Journal"])
    }

    @Test func languagesToDownloadAreListedBeforeStarting() async {
        let model = await makeModel(translator: FakeListingTranslator(availability: [.german: .needsDownload]))
        model.presentTranslate()
        await model.translation.checkAvailability()
        #expect(model.translation.localesNeedingDownload == [.german])
        #expect(model.translation.unsupportedLocales.isEmpty)
    }

    // MARK: - Running

    @Test func translatesAndCopiesIntoSuggestions() async throws {
        let model = await makeModel()
        model.presentTranslate()
        await runToSuggestions(model)

        let review = try #require(model.translation.review)
        #expect(model.translation.phase == .reviewing)
        #expect(model.sheet == nil)
        #expect(review.suggestions.count == 6)
        let keywords = try #require(review.suggestions.first { $0.key == ListingFieldKey(.german, .keywords) })
        #expect(keywords.suggestedText == "[de-DE] diary,mood,gratitude")
        #expect(keywords.currentText.isEmpty)
        let support = try #require(review.suggestions.first { $0.key == ListingFieldKey(.german, .supportURL) })
        #expect(support.suggestedText == "https://lumen.example/support")
    }

    @Test func glossaryTermsAreNeverSentToTheTranslator() async throws {
        let translator = FakeListingTranslator()
        let model = await makeModel(translator: translator)
        model.presentTranslate(scope: TranslationScope(fields: [.promotionalText], locales: [.german]))
        model.translation.glossary.add("Weekly Reflections")
        await runToSuggestions(model)

        let sent = try #require(translator.sent.texts.first)
        #expect(!sent.contains("Weekly Reflections"))
        let suggestion = try #require(model.translation.review?.suggestions.first)
        #expect(suggestion.suggestedText.contains("Weekly Reflections"))
    }

    @Test func undownloadedLanguagesFailWithAReason() async {
        let model = await makeModel(translator: FakeListingTranslator(availability: [.german: .needsDownload]))
        model.presentTranslate(scope: TranslationScope(fields: [.keywords, .supportURL], locales: [.german]))
        await runToSuggestions(model)

        #expect(model.translation.review?.suggestions.map(\.key) == [ListingFieldKey(.german, .supportURL)])
        #expect(model.translation.failureSummary == "1 field couldn’t be translated. German isn’t downloaded for Apple Translation.")
    }

    @Test func theAIProviderTranslatesWithTheSheetsToneAndSkipsAppleTranslation() async throws {
        let apple = FakeListingTranslator(availability: [.german: .needsDownload])
        let model = await makeModel(translator: apple)
        let tones = ToneLog()
        model.presentTranslate(scope: TranslationScope(fields: [.keywords], locales: [.german]))
        model.translation.provider = .aiProvider
        model.translation.glossary.tone = .playful
        model.translation.aiProvider = AIProviderSetup(vendor: .anthropic, hasKey: true) { tone in
            tones.append(tone)
            return FakeListingTranslator()
        }
        await runToSuggestions(model)

        #expect(tones.tones == [.playful])
        #expect(apple.sent.texts.isEmpty)
        let suggestion = try #require(model.translation.review?.suggestions.first)
        #expect(suggestion.suggestedText == "[de-DE] diary,mood,gratitude")
        #expect(model.translation.failureSummary == nil)
    }

    @Test func translatorErrorsAreListed() async {
        let model = await makeModel(translator: FakeListingTranslator(failing: [ListingFieldKey(.german, .keywords)]))
        model.presentTranslate(scope: TranslationScope(fields: [.keywords, .whatsNew], locales: [.german]))
        await runToSuggestions(model)
        #expect(model.translation.review?.suggestions.map(\.key) == [ListingFieldKey(.german, .whatsNew)])
        #expect(model.translation.failureSummary?.hasPrefix("1 field couldn’t be translated.") == true)
    }

    // MARK: - Suggestions

    @Test func onlyAcceptedSuggestionsAreQueuedAsMachineTranslation() async {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.presentTranslate(scope: TranslationScope(fields: [.keywords, .whatsNew], locales: [.german]))
        await runToSuggestions(model)
        model.translation.accept(ListingFieldKey(.german, .keywords))
        model.translation.reject(ListingFieldKey(.german, .whatsNew))
        #expect(model.translation.review?.statusLine == "1 accepted · 0 to decide")
        model.finishSuggestions()

        #expect(model.translation.phase == .idle)
        #expect(queue.changes.map(\.id) == [StorePageContentFixtures.changeID(.german, .keywords)])
        #expect(queue.changes.first?.source == .machineTranslation)
        #expect(model.draft(.keywords, in: .german).isMachineTranslated)
        #expect(model.value(.whatsNew, in: .german).isEmpty)
        #expect(model.notice == "Added 1 translation to Review & Push.")
    }

    @Test func undoPutsASuggestionBackToDecide() async {
        let model = await makeModel()
        model.presentTranslate(scope: TranslationScope(fields: [.keywords], locales: [.german]))
        await runToSuggestions(model)
        let key = ListingFieldKey(.german, .keywords)
        model.translation.accept(key)
        model.translation.undo(key)
        #expect(model.translation.review?.pendingCount == 1)
        model.translation.rejectAll()
        model.finishSuggestions()
        #expect(model.queue.changes.isEmpty)
    }

    /// The tones the AI provider's translator was made with.
    final class ToneLog: Sendable {
        private let storage = Mutex<[TranslationTone]>([])

        var tones: [TranslationTone] { storage.withLock { $0 } }

        func append(_ tone: TranslationTone) {
            storage.withLock { $0.append(tone) }
        }
    }

    @Test func whatsNewGoesToEveryLocaleReplacingWhatsThere() async {
        let model = await makeModel()
        model.addLocale(.french)
        model.edit(.whatsNew, in: .german, to: "Fehlerbehebungen.")
        model.presentWhatsNewBroadcast()
        #expect(model.translation.isSendingWhatsNew)
        #expect(Set(model.translation.plan.items.map(\.key)) == [ListingFieldKey(.german, .whatsNew), ListingFieldKey(.french, .whatsNew)])
    }
}
