//
//  PrivacyURLsTableTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The Privacy URLs tab's table: the Privacy Policy URL's edits are Store
/// Page's own changes (same id, same write), the User Privacy Choices URL's
/// are App Information's, and queued edits show on top of App Store
/// Connect's values.
@Suite("PrivacyURLsTable")
struct PrivacyURLsTableTests {
    private let appID = AppInformationTestSupport.appID
    private let content = PrivacyURLsContent(
        appInfoID: "info-next",
        primaryLocale: .englishUS,
        locales: [
            PrivacyURLsLocale(locale: .englishUS, localizationID: "loc-en", policyURL: "https://lumen.example/privacy", choicesURL: "https://lumen.example/choices"),
            PrivacyURLsLocale(locale: .frenchCanada, localizationID: "loc-frca"),
            PrivacyURLsLocale(locale: .german, localizationID: "loc-de", policyURL: "https://lumen.example/privacy"),
        ]
    )

    private func table(_ changes: [PendingChange] = []) -> PrivacyURLsTable {
        PrivacyURLsTable(appID: appID, content: content, changes: changes)
    }

    @Test func aPolicyURLEditIsStorePagesOwnChange() throws {
        let (id, change) = table().policyChange(.frenchCanada, to: " https://lumen.example/fr/confidentialite ")
        #expect(id == "storePage.\(appID).appInfo.info-next.fr-CA.privacyPolicyUrl")
        let storePage = ListingChangeBuilder(appID: appID, ids: ListingResourceIDs(versionID: "v14", appInfoID: "info-next"), versionString: "1.4")
        #expect(id == storePage.changeID(for: ListingFieldKey(.frenchCanada, .privacyPolicyURL)))
        let queued = try #require(change)
        #expect(queued.section == .storePage)
        #expect(queued.newValue == "https://lumen.example/fr/confidentialite")
        let request = try #require(queued.requests.first)
        #expect(request.path == "/v1/appInfoLocalizations/loc-frca")
        #expect(AppInformationTestSupport.attributes(request)["privacyPolicyUrl"] as? String == "https://lumen.example/fr/confidentialite")
    }

    @Test func queuedEditsShowOnTopAndGoAwayWhenUndone() throws {
        let change = try #require(table().policyChange(.frenchCanada, to: "https://lumen.example/fr").change)
        let edited = table([change])
        #expect(edited.policyURL(.frenchCanada) == "https://lumen.example/fr")
        #expect(edited.isPolicyPending(.frenchCanada))
        #expect(!edited.isPolicyPending(.german))
        #expect(edited.policyCount == 3)
        #expect(edited.missingPolicyLocales.isEmpty)
        #expect(edited.policyChange(.frenchCanada, to: "").change == nil)
    }

    @Test func aChoicesURLIsAnAppInformationChange() throws {
        let (id, change) = table().choicesChange(.german, to: "https://lumen.example/de/choices")
        #expect(id == "appInformation.\(appID).appPrivacy.choices.de-DE")
        let queued = try #require(change)
        #expect(queued.section == .appInformation)
        #expect(queued.blockedReason == nil)
        let request = try #require(queued.requests.first)
        #expect(request.path == "/v1/appInfoLocalizations/loc-de")
        #expect(AppInformationTestSupport.attributes(request)["privacyChoicesUrl"] as? String == "https://lumen.example/de/choices")

        let edited = table([queued])
        #expect(edited.choicesURL(.german) == "https://lumen.example/de/choices")
        #expect(edited.isChoicesPending(.german))
        #expect(edited.choicesCount == 2)
        #expect(edited.choicesChange(.german, to: "").change == nil)
    }

    @Test func clearingAChoicesURLIsAllowedButAnInvalidOneIsBlocked() throws {
        let cleared = try #require(table().choicesChange(.englishUS, to: "").change)
        #expect(cleared.blockedReason == nil)
        let invalid = try #require(table().choicesChange(.englishUS, to: "lumen.example/choices").change)
        #expect(invalid.blockedReason != nil)
    }

    @Test func theProblemsAndCoverage() {
        let table = table()
        #expect(table.policyProblem(.frenchCanada) == "Required")
        #expect(table.policyProblem(.englishUS) == nil)
        #expect(table.choicesProblem(.frenchCanada) == nil)
        #expect(table.policyCount == 2)
        #expect(table.choicesCount == 1)
        #expect(table.missingPolicyLocales == [.frenchCanada])
        let summary = AppInformationSummary.PrivacyURLs(table: table)
        #expect(summary == AppInformationSummary.PrivacyURLs(localeCount: 3, policyCount: 2, choicesCount: 1))
        #expect(summary.missingPolicyCount == 1)
    }

    @Test func anInvalidPolicyURLSaysWhy() throws {
        let change = try #require(table().policyChange(.german, to: "lumen.example").change)
        #expect(table([change]).policyProblem(.german) == ListingBlockReason.invalidURL.message)
    }
}
