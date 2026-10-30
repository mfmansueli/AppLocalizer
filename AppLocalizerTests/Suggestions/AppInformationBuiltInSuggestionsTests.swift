//
//  AppInformationBuiltInSuggestionsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// App Information's built-in checks: an old copyright year, and contact
/// details the previous version had, only on an editable version.
@Suite("AppInformationBuiltInSuggestions")
struct AppInformationBuiltInSuggestionsTests {
    private let appID = "6450000001"
    private let now = Date(timeIntervalSince1970: 1_792_000_000) // October 2026
    private let editable = StorePageVersion(id: "v14", listingVersion: ListingVersion("1.4", state: .prepareForSubmission), platform: "IOS")
    private let live = StorePageVersion(id: "v13", listingVersion: ListingVersion("1.3", state: .readyForDistribution), platform: "IOS")

    @Test func anOldCopyrightYearMovesToThisYear() throws {
        let suggestion = try #require(AppInformationBuiltInSuggestions.copyright("© 2025 Northpier Studio", version: "1.4", appID: appID, now: now))
        #expect(suggestion.value == "© 2026 Northpier Studio")
        #expect(suggestion.reason == "Still says 2025, and 1.4 will ship in 2026.")
        #expect(suggestion.source == .builtIn)
        #expect(suggestion.target == .appInformation(.copyright))
    }

    @Test func onlyTheLastYearOfARangeMoves() {
        let suggestion = AppInformationBuiltInSuggestions.copyright("© 2019–2025 Northpier", version: "1.4", appID: appID, now: now)
        #expect(suggestion?.value == "© 2019–2026 Northpier")
    }

    @Test func thisYearOrNoYearSuggestsNothing() {
        #expect(AppInformationBuiltInSuggestions.copyright("© 2026 Northpier", version: "1.4", appID: appID, now: now) == nil)
        #expect(AppInformationBuiltInSuggestions.copyright("Northpier Studio", version: "1.4", appID: appID, now: now) == nil)
    }

    @Test func emptyContactDetailsComeFromThePreviousVersion() {
        let review = AppReviewValues(firstName: "Ana", lastName: "", phone: "", email: "review@northpier.dev")
        let previous = AppInformationBuiltInSuggestions.PreviousReview(
            versionString: "1.3",
            review: AppReviewValues(firstName: "Giulia", lastName: "Ferraro", phone: "+39 011 555 0142", email: "")
        )
        let found = AppInformationBuiltInSuggestions.suggestions(general: nil, review: review, version: editable, previous: previous, appID: appID, now: now)
        #expect(found.map(\.target.field) == ["contactLastName", "contactPhone"])
        #expect(found.map(\.value) == ["Ferraro", "+39 011 555 0142"])
        #expect(found.last?.reason == "The phone number from 1.3’s App Review details.")
    }

    @Test func aVersionInReviewOrLiveGetsNone() {
        let general = GeneralValues(copyright: "© 2025 Northpier")
        let found = AppInformationBuiltInSuggestions.suggestions(general: general, review: nil, version: live, previous: nil, appID: appID, now: now)
        #expect(found.isEmpty)
    }

    @Test func fieldsNormalizeAndShowPickedValuesByName() {
        #expect(AppInformationSuggestionField.secondaryCategory.normalized("productivity") == "PRODUCTIVITY")
        #expect(AppInformationSuggestionField.primaryCategory.normalized("Health & Fitness") == "HEALTH_AND_FITNESS")
        #expect(AppInformationSuggestionField.primaryCategory.normalized("Gardening") == nil)
        #expect(AppInformationSuggestionField.release.normalized("Automatically after approval") == "AFTER_APPROVAL")
        #expect(AppInformationSuggestionField.release.displayValue("MANUAL") == "Manually")
        #expect(AppInformationSuggestionField.contactPhone.normalized("  +39 011 ") == "+39 011")
        #expect(AppInformationSuggestionField(reviewField: .notes) == .notes)
        #expect(AppInformationSuggestionField(reviewField: .password) == nil)
        #expect(AppInformationSuggestionField.fields(on: .appReview).count == 5)
    }
}
