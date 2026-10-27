//
//  LiveAppInformationServicesTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The live services against canned App Store Connect JSON: the pages, the
/// accessibility declarations, the privacy URLs and the summary. Nothing
/// reaches the network, and worksheets stay in memory.
@MainActor
@Suite("LiveAppInformationServices")
struct LiveAppInformationServicesTests {
    private typealias Canned = AppInformationCannedResponses
    private let app = AppInformationTestSupport.app

    private func services(_ transport: FakeHTTPTransport) -> LiveAppInformationServices {
        LiveAppInformationServices(
            client: AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport),
            notes: InMemoryAppInformationNotesStore(),
            privacy: InMemoryPrivacyWorksheetStore(),
            secrets: InMemorySecretStore()
        )
    }

    @Test func thePagesReadTheEditableVersionAndTheAppInfoBeingPrepared() async throws {
        let transport = FakeHTTPTransport(Canned.content)
        let content = try await services(transport).content(for: app, versionID: nil)

        #expect(content.version?.id == "v14")
        #expect(content.ids.appInfoID == "info-next")
        #expect(content.ids.ageRatingDeclarationID == "age-1")
        #expect(content.ids.reviewDetailID == "review-1")
        #expect(content.general.primaryCategory == "LIFESTYLE")
        #expect(content.general.secondaryCategory == nil)
        #expect(content.general.contentRights == .doesNotUseThirdPartyContent)
        #expect(content.general.copyright == "© 2026 Northpier Studio")
        #expect(content.general.release == .afterApproval)
        #expect(content.ageRating.currentRating == "9+")
        #expect(content.ageRating.answers[.wellness] == .affirmative)
        #expect(!content.ageRating.isAnswered(.messaging))
        #expect(content.ageRating.override == nil)
        #expect(content.review.firstName == "Ana")
        #expect(content.review.isComplete)
        #expect(content.export.buildID == "b42")
        #expect(content.export.usesNonExemptEncryption == false)
        #expect(content.export.declaredAnswers?[.availableInFrance] == true)

        let paths = transport.requests.compactMap(\.url?.path)
        #expect(paths == [
            "/v1/apps/6450000001/appStoreVersions", "/v1/apps/6450000001/appInfos", "/v1/appInfos/info-next", "/v1/apps/6450000001",
            "/v1/appInfos/info-next/ageRatingDeclaration", "/v1/appStoreVersions/v14/appStoreReviewDetail",
            "/v1/appStoreVersions/v14/build", "/v1/apps/6450000001/appEncryptionDeclarations",
        ])
        #expect(transport.requests.allSatisfy { $0.httpMethod == "GET" })
    }

    @Test func aVersionWithoutReviewDetailsOrBuildStillLoads() async throws {
        var responses = Canned.content
        responses[5] = Canned.notFound
        responses[6] = Canned.notFound
        let content = try await services(FakeHTTPTransport(responses)).content(for: app, versionID: nil)
        #expect(content.ids.reviewDetailID == nil)
        #expect(content.review == AppReviewValues())
        #expect(content.export.buildID == nil)
    }

    @Test func accessibilityLeavesOutReplacedDeclarationsAndKnowsWhatsLive() async throws {
        let content = try await services(FakeHTTPTransport(Canned.accessibility)).accessibility(for: app)
        #expect(content.declarations.map(\.id) == ["d1", "d2", "d3"])
        #expect(content.declaration(for: .iPhone, state: .published)?.answer.features == [.voiceOver, .largerText])
        #expect(content.families == [.iPhone, .iPad, .appleWatch, .vision])
        #expect(content.liveFamilies == [.iPhone, .iPad, .appleWatch])
        #expect(content.accessibilityURL == "https://lumen.example/accessibility")
        #expect(content.upcomingVersion == "1.4")
    }

    @Test func theSummaryHasTheRatingAppReviewTheWorksheetAndThePrivacyURLs() async throws {
        let summary = try await services(FakeHTTPTransport(Canned.content + Canned.privacyURLs)).summary(for: app)
        #expect(summary.ageRating == "9+")
        #expect(summary.isAppReviewComplete)
        #expect(summary.privacy.status == .notStarted)
        #expect(summary.privacyURLs == AppInformationSummary.PrivacyURLs(localeCount: 3, policyCount: 2, choicesCount: 1))
    }

    @Test func privacyURLsThatDontLoadLeaveTheSummaryWithoutThem() async throws {
        let summary = try await services(FakeHTTPTransport(Canned.content + [Canned.notFound])).summary(for: app)
        #expect(summary.ageRating == "9+")
        #expect(summary.privacyURLs == nil)
    }

    @Test func privacyURLsAreReadFromTheAppInfoBeingPrepared() async throws {
        let transport = FakeHTTPTransport(Canned.privacyURLs)
        let content = try await services(transport).privacyURLs(for: app)
        #expect(content.appInfoID == "info-next")
        #expect(content.primaryLocale.code == "en-US")
        #expect(content.locales.map(\.locale.code) == ["en-US", "fr-FR", "de-DE"])
        let english = try #require(StoreLocaleCatalog.locale(code: "en-US"))
        let french = try #require(StoreLocaleCatalog.locale(code: "fr-FR"))
        let german = try #require(StoreLocaleCatalog.locale(code: "de-DE"))
        #expect(content.remote(english)?.choicesURL == "https://lumen.example/privacy/choices")
        #expect(content.remote(german)?.policyURL == "")
        #expect(content.remote(french)?.localizationID == "loc-fr")
        let last = try #require(transport.requests.last?.url)
        #expect(last.path == "/v1/appInfos/info-next/appInfoLocalizations")
        let fields = URLComponents(url: last, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "fields[appInfoLocalizations]" }
        #expect(fields?.value == "locale,privacyPolicyUrl,privacyChoicesUrl")
    }

    @Test func aServerErrorIsThrown() async {
        let failure = CannedHTTPResponse(statusCode: 500, body: #"{"errors":[{"status":"500","code":"UNEXPECTED_ERROR","title":"x","detail":"Boom"}]}"#)
        await #expect(throws: AppStoreConnectError.self) {
            try await services(FakeHTTPTransport([failure])).accessibility(for: app)
        }
    }
}
