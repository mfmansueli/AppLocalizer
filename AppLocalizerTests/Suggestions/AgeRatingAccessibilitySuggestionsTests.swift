//
//  AgeRatingAccessibilitySuggestionsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Suggestions for Age Rating's questions and Accessibility's features on
/// Lumen's sample: answers go in as the person's would, accepted answers
/// don't ask for Confirmed again, Undo takes them back to unanswered, the
/// built-in advertising check reads App Privacy's scan, and Accessibility
/// works one device at a time.
@MainActor
@Suite("Age Rating and Accessibility suggestions")
struct AgeRatingAccessibilitySuggestionsTests {
    private let queue = ChangeQueue()
    private let store = FieldSuggestionStore()
    private let app = StoreApp(id: DebugFixtures.AppID.lumen, name: "Lumen Journal", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")
    private let claude = SuggestionSource.assistant(client: "Claude Code")

    private func loaded() async -> AppInformationViewModel {
        let viewModel = AppInformationViewModel(app: app, services: DebugAppInformationServices(), queue: queue, suggestions: store)
        await viewModel.load()
        return viewModel
    }

    @discardableResult
    private func suggest(_ slot: AppInformationSuggestionSlot, _ value: String) -> FieldSuggestion {
        store.add(appID: app.id, target: slot.target, value: value, reason: "From the code.", source: claude).suggestion
    }

    @Test func acceptingAnAnswerQueuesItWithoutAskingToConfirm() async throws {
        let vm = await loaded()
        let wellness = AppInformationSuggestionSlot.ageRating(.wellness)
        #expect(vm.suggestionValue(wellness) == "")
        vm.acceptSuggestion(suggest(wellness, "affirmative"))

        let change = try #require(queue.change(id: vm.builder.changeID(.ageRating, "wellness")))
        #expect(change.source == claude.changeSource)
        #expect(vm.suggestionValue(wellness) == "affirmative")
        #expect(vm.ageRating?.answers[.wellness] == .affirmative)
        #expect(vm.provenance(wellness) != nil)
        #expect(vm.assistantAnswers[.wellness] == nil)
        #expect(vm.shownSuggestion(wellness) == nil)
        #expect(vm.suggestionToast?.text == "Health or wellness topics accepted. It’s in Review & Push.")
    }

    @Test func undoTakesTheQuestionBackToUnanswered() async {
        let vm = await loaded()
        let wellness = AppInformationSuggestionSlot.ageRating(.wellness)
        vm.acceptSuggestion(suggest(wellness, "affirmative"))
        vm.undoSuggestion(wellness)
        #expect(queue.change(id: vm.builder.changeID(.ageRating, "wellness")) == nil)
        #expect(vm.suggestionValue(wellness) == "")
        #expect(vm.shownSuggestion(wellness)?.value == "affirmative")
    }

    @Test func onlyQuestionsWithSuggestionsOrChanges() async {
        let vm = await loaded()
        suggest(.ageRating(.webAccess), "negative")
        vm.showsOnlySuggestedFields = true
        #expect(vm.showsField(.ageRating(.webAccess)))
        #expect(!vm.showsField(.ageRating(.horror)))
    }

    @Test func theAdvertisingCheckReadsAppPrivacysScan() throws {
        var worksheet = DebugPrivacyWorksheets.overview
        let suggestion = try #require(AppInformationBuiltInSuggestions.advertising(current: "", worksheet: worksheet, appID: app.id))
        #expect(suggestion.target == AppInformationSuggestionSlot.ageRating(.advertising).target)
        #expect(suggestion.value == "negative")
        #expect(suggestion.source == .builtIn)
        #expect(suggestion.reason == "App Privacy’s last scan found no advertising SDKs, and no data type is used for ads.")
        #expect(AppInformationBuiltInSuggestions.advertising(current: "affirmative", worksheet: worksheet, appID: app.id) == nil)

        worksheet.scans[worksheet.scans.count - 1].sdks.append(PrivacySDK(name: "GoogleMobileAds", version: "11.2.0"))
        #expect(AppInformationBuiltInSuggestions.advertising(current: "", worksheet: worksheet, appID: app.id) == nil)
        #expect(AppInformationBuiltInSuggestions.advertising(current: "", worksheet: PrivacyWorksheet(), appID: app.id) == nil)
    }

    @Test func accessibilityWorksOneDeviceAtATime() async {
        let vm = await loaded()
        suggest(.accessibility(.appleWatch, .voiceOver), "yes")
        suggest(.accessibility(.iPhone, .reducedMotion), "yes")
        #expect(vm.accessibilitySuggestionFamilies == [.iPhone, .iPad, .appleWatch, .vision])
        #expect(vm.suggestionCount(in: .accessibility(.appleWatch)) == 1)
        #expect(vm.suggestionCount(on: .accessibility) == 2)

        vm.acceptAllSuggestions(in: .accessibility(.appleWatch))
        #expect(vm.card(for: .appleWatch)?.queued?.features == [.voiceOver])
        #expect(vm.isPending(.accessibility(.appleWatch, .voiceOver)))
        #expect(vm.provenance(.accessibility(.appleWatch, .voiceOver)) != nil)
        #expect(vm.suggestionCount(in: .accessibility(.iPhone)) == 1)
        #expect(vm.suggestionToast?.text == "Accepted 1 on Accessibility · Apple Watch. It’s in Review & Push.")
    }

    @Test func acceptingTwoFeaturesKeepsBoth() async {
        let vm = await loaded()
        suggest(.accessibility(.appleWatch, .voiceOver), "yes")
        suggest(.accessibility(.appleWatch, .largerText), "yes")
        vm.acceptAllSuggestions(in: .accessibility(.appleWatch))
        #expect(vm.card(for: .appleWatch)?.queued?.features == [.voiceOver, .largerText])
        vm.undoSuggestion(.accessibility(.appleWatch, .voiceOver))
        #expect(vm.card(for: .appleWatch)?.queued?.features == [.largerText])
    }

    @Test func anAPIKeyCountsWhatOnlyTheCodeCanAnswer() async {
        let vm = await loaded()
        // Seven unanswered; Advertising has the built-in check's answer
        // once App Privacy's scan is read.
        let unanswered = vm.shownSuggestion(.ageRating(.advertising), filter: .all) == nil ? 7 : 6
        #expect(vm.codeOnlyAnswerCount(in: .appInformation(.ageRating)) == unanswered)
        suggest(.ageRating(.wellness), "affirmative")
        #expect(vm.codeOnlyAnswerCount(in: .appInformation(.ageRating)) == unanswered - 1)
        #expect(vm.codeOnlyAnswerCount(in: .appInformation(.general)) == 2)
        #expect(vm.codeOnlyAnswerCount(in: .appInformation(.appReview)) == 1)
        #expect(vm.codeOnlyAnswerCount(in: .accessibility(.iPhone)) == 0)
        #expect(vm.codeOnlyAnswerCount(in: .accessibility(.appleWatch)) == DeviceFamily.appleWatch.features.count)
    }

    @Test func askingOpensTheFirstDeviceWithSuggestions() async {
        let vm = await loaded()
        for page in [AppInformationPage.general, .ageRating, .appReview] {
            vm.dismissAllSuggestions(in: .appInformation(page))
        }
        suggest(.accessibility(.appleWatch, .voiceOver), "yes")
        vm.openSuggestions()
        #expect(vm.page == .accessibility)
        #expect(vm.accessibilitySuggestionFamily == .appleWatch)
        #expect(vm.shownAccessibilitySuggestionFamily == .appleWatch)
    }
}
#endif
