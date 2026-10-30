//
//  StorePageSuggestionsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Suggestions on the Store Page editor, on the fixture listing (English
/// with every field, German without its URLs): the built-in checks,
/// accepting one, all or everywhere, undoing, and the bar's counts.
@MainActor
@Suite("Store Page suggestions")
struct StorePageSuggestionsTests {
    private let app = StorePageContentFixtures.app
    private let queue = ChangeQueue()
    private let store = FieldSuggestionStore()
    private let claude = SuggestionSource.assistant(client: "Claude Code")

    private func loaded() async -> StorePageViewModel {
        let model = StorePageViewModel(app: app, services: FakeStorePageServices(), queue: queue, suggestions: store)
        await model.load()
        return model
    }

    @discardableResult
    private func suggest(_ field: ListingField, in locale: StoreLocale, _ value: String, source: SuggestionSource? = nil) -> FieldSuggestion {
        store.add(appID: app.id, target: .storePage(locale, field), value: value, reason: "From the commits.", source: source ?? claude).suggestion
    }

    @Test func emptyURLsGetTheOnesOtherLanguagesUse() async throws {
        let model = await loaded()
        let support = try #require(model.shownSuggestion(.supportURL, in: .german))
        #expect(support.source == .builtIn)
        #expect(support.value == "https://lumen.example/support")
        #expect(model.suggestionCount(in: .german) > 0)
    }

    @Test func acceptingQueuesTheValueTaggedWithTheAssistant() async throws {
        let model = await loaded()
        model.acceptSuggestion(suggest(.whatsNew, in: .englishUS, "• Weekly reflections"))
        let change = try #require(queue.change(id: StorePageContentFixtures.changeID(.englishUS, .whatsNew)))
        #expect(change.newValue == "• Weekly reflections")
        #expect(change.source == .assistant(client: "Claude Code"))
        #expect(model.value(.whatsNew, in: .englishUS) == "• Weekly reflections")
        #expect(model.provenance(.whatsNew, in: .englishUS)?.source == claude)
        #expect(model.toast?.canUndo == true)
        #expect(model.shownSuggestion(.whatsNew, in: .englishUS) == nil)
    }

    @Test func anAcceptedValueReplacesYourEditInsteadOfConflicting() async throws {
        let model = await loaded()
        model.edit(.whatsNew, in: .englishUS, to: "Mine")
        model.acceptSuggestion(suggest(.whatsNew, in: .englishUS, "Theirs"))
        let change = try #require(queue.change(id: StorePageContentFixtures.changeID(.englishUS, .whatsNew)))
        #expect(change.newValue == "Theirs")
        #expect(change.alternative == nil)

        model.undoSuggestion(.whatsNew, in: .englishUS)
        #expect(model.value(.whatsNew, in: .englishUS) == "Mine")
        #expect(model.shownSuggestion(.whatsNew, in: .englishUS)?.value == "Theirs")
    }

    @Test func acceptAllAndItsUndo() async {
        let model = await loaded()
        suggest(.whatsNew, in: .englishUS, "• Weekly reflections")
        suggest(.promotionalText, in: .englishUS, "Weekly reflections are here: every Sunday.")
        #expect(model.visibleSuggestions(in: .englishUS).count == 2)

        model.acceptAllSuggestions(in: .englishUS)
        #expect(model.toast?.text == "Accepted 2 suggestions in English (U.S.). Nothing is pushed yet.")
        #expect(model.value(.promotionalText, in: .englishUS) == "Weekly reflections are here: every Sunday.")
        #expect(model.visibleSuggestions(in: .englishUS).isEmpty)

        model.undoLastSuggestionBatch()
        #expect(model.value(.whatsNew, in: .englishUS) == "Weekly Reflections and bug fixes.")
        #expect(model.visibleSuggestions(in: .englishUS).count == 2)
        #expect(queue.changes(for: app.id, section: .storePage).isEmpty)
        #expect(model.toast == nil)
    }

    @Test func theFilterNarrowsWhatAcceptAllTakes() async {
        let model = await loaded()
        suggest(.whatsNew, in: .englishUS, "Claude")
        suggest(.promotionalText, in: .englishUS, "Provider", source: .aiProvider)
        model.suggestionFilter = .aiProvider
        let bar = model.suggestionBar(for: .englishUS, assistant: nil)
        #expect(bar.openCount == 2)
        #expect(bar.visibleCount == 1)
        #expect(bar.assistantName == "Claude Code")
        model.acceptAllSuggestions(in: .englishUS)
        #expect(model.value(.promotionalText, in: .englishUS) == "Provider")
        #expect(model.value(.whatsNew, in: .englishUS) == "Weekly Reflections and bug fixes.")
    }

    @Test func acceptingEverywhereTakesEveryLanguage() async {
        let model = await loaded()
        suggest(.whatsNew, in: .englishUS, "English")
        suggest(.whatsNew, in: .german, "Deutsch")
        let germanBefore = model.visibleSuggestions(in: .german).count
        #expect(model.suggestionBar(for: .englishUS, assistant: nil).otherScopesCount == germanBefore)
        model.acceptSuggestionsEverywhere()
        #expect(model.value(.whatsNew, in: .german) == "Deutsch")
        #expect(model.totalSuggestionCount == 0)
    }

    @Test func useAndEditAsksForFocus() async {
        let model = await loaded()
        model.useAndEditSuggestion(suggest(.subtitle, in: .englishUS, "Private diary, mood & prompts"))
        #expect(model.focusRequest == ListingFieldKey(.englishUS, .subtitle))
        #expect(model.provenance(.subtitle, in: .englishUS)?.isForEditing == true)
        #expect(model.toast == nil)
    }

    @Test func onlyFieldsWithSuggestionsOrChanges() async {
        let model = await loaded()
        suggest(.whatsNew, in: .englishUS, "New")
        model.edit(.keywords, in: .englishUS, to: "diary,mood")
        model.showsOnlySuggestedFields = true
        #expect(model.editorFields(in: .englishUS) == [.keywords, .whatsNew])
    }

    @Test func dismissingAndRestoring() async {
        let model = await loaded()
        suggest(.whatsNew, in: .englishUS, "New")
        model.dismissAllSuggestions(in: .englishUS)
        #expect(model.visibleSuggestions(in: .englishUS).isEmpty)
        #expect(model.suggestionBar(for: .englishUS, assistant: nil).dismissedCount == 1)
        model.restoreDismissedSuggestions(in: .englishUS)
        #expect(model.visibleSuggestions(in: .englishUS).count == 1)
    }

    @Test func askingOpensTheFirstLanguageWithSuggestions() async {
        let model = await loaded()
        model.dismissAllSuggestions(in: .englishUS)
        suggest(.whatsNew, in: .german, "Deutsch")
        #expect(StorePageViewModel.handles(.askForSuggestions(.storePage)))
        #expect(!StorePageViewModel.handles(.askForSuggestions(.appInformation)))
        model.handle(.askForSuggestions(.storePage))
        #expect(model.editorLocale == .german)
        #expect(model.requestsAsk)
    }
}
