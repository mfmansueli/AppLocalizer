//
//  AppInformationSuggestionsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Suggestions on App Information's General and App Review, on the sample
/// services with Lumen's 1.4 still saying © 2025 and missing the contact
/// phone 1.3 had: the built-in checks, accepting (one, all, Use and Edit),
/// undoing, and a locked version.
@MainActor
@Suite("App Information suggestions")
struct AppInformationSuggestionsTests {
    private let queue = ChangeQueue()
    private let store = FieldSuggestionStore()
    private let app = StoreApp(id: DebugFixtures.AppID.lumen, name: "Lumen Journal", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")
    private let claude = SuggestionSource.assistant(client: "Claude Code")
    private let year = Calendar(identifier: .gregorian).component(.year, from: .now)

    private func loaded() async -> AppInformationViewModel {
        var services = DebugAppInformationServices()
        services.hasOutdatedDetails = true
        let viewModel = AppInformationViewModel(app: app, services: services, queue: queue, suggestions: store)
        await viewModel.load()
        return viewModel
    }

    @discardableResult
    private func suggest(_ field: AppInformationSuggestionField, _ value: String) -> FieldSuggestion {
        store.add(appID: app.id, target: .appInformation(field), value: value, reason: "From the code.", source: claude).suggestion
    }

    @Test func theBuiltInChecksFindTheCopyrightAndThePhone() async throws {
        let vm = await loaded()
        let copyright = try #require(vm.shownSuggestion(.copyright))
        #expect(copyright.value == "© \(year) Northpier Studio")
        #expect(copyright.source == .builtIn)
        #expect(vm.shownSuggestion(.contactPhone)?.value == "+39 011 555 0142")
        #expect(vm.suggestionCount(on: .general) == 1)
        #expect(vm.suggestionCount(on: .appReview) == 1)
        #expect(vm.suggestionBar(for: .general, assistant: nil).countText == "1 suggestion")
        #expect(vm.showsSuggestions(on: .general))
        #expect(vm.showsSuggestions(on: .ageRating))
        #expect(!vm.showsSuggestions(on: .appPrivacy))
    }

    @Test func acceptingQueuesTheValueTaggedWithItsSource() async throws {
        let vm = await loaded()
        let copyright = try #require(vm.shownSuggestion(.copyright))
        vm.acceptSuggestion(copyright)

        let change = try #require(queue.changes.first)
        #expect(queue.changes.count == 1)
        #expect(change.source == .builtInSuggestion)
        #expect(vm.general?.copyright == "© \(year) Northpier Studio")
        #expect(vm.shownSuggestion(.copyright) == nil)
        #expect(vm.provenance(.copyright)?.line(currentValue: vm.suggestionValue(.copyright)) == "Accepted a built-in suggestion.")
        #expect(vm.suggestionToast?.text == "Accepted the Copyright suggestion. Nothing is pushed yet.")
        #expect(vm.suggestionToast?.canUndo == true)
    }

    @Test func theToastsUndoPutsTheFieldAndTheSuggestionBack() async throws {
        let vm = await loaded()
        try vm.acceptSuggestion(#require(vm.shownSuggestion(.copyright)))
        vm.undoLastSuggestionBatch()
        #expect(queue.changes.isEmpty)
        #expect(vm.general?.copyright == "© 2025 Northpier Studio")
        #expect(vm.shownSuggestion(.copyright) != nil)
        #expect(vm.suggestionToast == nil)
        #expect(vm.provenance(.copyright) == nil)
    }

    @Test func theProvenanceUndoRestoresWhatTheFieldHeld() async throws {
        let vm = await loaded()
        vm.setCopyright("© 2025 Northpier Studio Ltd")
        try vm.acceptSuggestion(#require(vm.shownSuggestion(.copyright)))
        vm.undoSuggestion(.copyright)
        #expect(vm.general?.copyright == "© 2025 Northpier Studio Ltd")
        #expect(queue.changes.first?.source == .you)
    }

    @Test func anAssistantsValueReplacesYourOwnEditInsteadOfConflicting() async {
        let vm = await loaded()
        vm.setSecondaryCategory("BOOKS")
        vm.acceptSuggestion(suggest(.secondaryCategory, "PRODUCTIVITY"))
        #expect(queue.changes.count == 1)
        #expect(queue.changes.first?.source == claude.changeSource)
        #expect(queue.changes.first?.alternative == nil)
        #expect(vm.general?.secondaryCategory == "PRODUCTIVITY")
    }

    @Test func acceptAllTakesThePagesSuggestions() async {
        let vm = await loaded()
        suggest(.notes, "Settings → Debug → Add Sample Week shows Weekly Reflections.")
        vm.acceptAllSuggestions(on: .appReview)
        #expect(vm.review?.phone == "+39 011 555 0142")
        #expect(vm.review?.notes == "Settings → Debug → Add Sample Week shows Weekly Reflections.")
        #expect(vm.suggestionCount(on: .appReview) == 0)
        #expect(vm.suggestionCount(on: .general) == 1)
        #expect(vm.suggestionToast?.text == "Accepted 2 suggestions on App Review. Nothing is pushed yet.")
        #expect(vm.suggestionBar(for: .appReview, assistant: nil).countText == "All suggestions reviewed")
    }

    @Test func useAndEditFocusesTheField() async throws {
        let vm = await loaded()
        try vm.useAndEditSuggestion(#require(vm.shownSuggestion(.contactPhone)))
        #expect(vm.focusRequest == .contactPhone)
        #expect(vm.provenance(.contactPhone)?.isForEditing == true)
        #expect(vm.suggestionToast == nil)
    }

    @Test func dismissingAndRestoring() async {
        let vm = await loaded()
        vm.dismissAllSuggestions(on: .general)
        #expect(vm.suggestionCount(on: .general) == 0)
        #expect(vm.suggestionBar(for: .general, assistant: nil).dismissedCount == 1)
        vm.restoreDismissedSuggestions(on: .general)
        #expect(vm.suggestionCount(on: .general) == 1)
    }

    @Test func onlyFieldsWithSuggestionsOrChanges() async {
        let vm = await loaded()
        vm.showsOnlySuggestedFields = true
        #expect(vm.showsField(.copyright))
        #expect(!vm.showsField(.primaryCategory))
        vm.setPrimaryCategory("BOOKS")
        #expect(vm.showsField(.primaryCategory))
    }

    @Test func aLiveVersionTakesOnlyTheAppsCategories() async {
        let vm = await loaded()
        suggest(.secondaryCategory, "PRODUCTIVITY")
        suggest(.notes, "Notes")
        await vm.selectVersion(DebugAppInformationContent.liveVersionID)
        #expect(vm.shownSuggestion(.copyright) == nil)
        #expect(vm.shownSuggestion(.notes) == nil)
        #expect(vm.shownSuggestion(.secondaryCategory)?.value == "PRODUCTIVITY")
    }

    @Test func askingOpensThePageWithSuggestions() async {
        let vm = await loaded()
        vm.page = .exportCompliance
        #expect(vm.handle(.askForSuggestions(.appInformation)))
        #expect(vm.page == .general)
        #expect(vm.requestsAsk)
        #expect(!vm.handle(.reviewFieldSuggestions(.storePage)))
        #expect(vm.suggestionPrompt() == """
        Suggest App Information and App Review details for Lumen Journal 1.4 in AppLocalizer, from the code, and App \
        Review's contact if it's empty.
        """)
    }

    @Test func theWriterRefusesALockedVersionAndADatelessSchedule() async throws {
        let vm = await loaded()
        let content = try #require(vm.content)
        let general = try #require(vm.general)
        let review = try #require(vm.review)
        let values = AppInformationSuggestionWriter.Values(content: content, general: general, review: review, builder: vm.builder)
        var dateless = values
        dateless.general.earliestReleaseDate = nil
        #expect(AppInformationSuggestionWriter.change(.release, to: "SCHEDULED", in: dateless, source: .you) == nil)
        let written = try #require(AppInformationSuggestionWriter.change(.release, to: "AFTER_APPROVAL", in: values, source: .you))
        #expect(written.change?.newValue != nil)

        var locked = values
        locked.content.versions = [DebugAppInformationContent.versions[1]]
        locked.content.version = DebugAppInformationContent.versions[1]
        #expect(AppInformationSuggestionWriter.change(.copyright, to: "© 2027", in: locked, source: .you) == nil)
        #expect(AppInformationSuggestionWriter.change(.primaryCategory, to: "BOOKS", in: locked, source: .you) != nil)
    }
}
#endif
