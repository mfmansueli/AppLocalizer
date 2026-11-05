//
//  StorePageContentLoaderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The live reads against canned App Store Connect JSON. Nothing reaches
/// Apple: `FakeHTTPTransport` answers in order.
@Suite("StorePageContentLoader")
struct StorePageContentLoaderTests {
    private typealias Canned = StorePageCannedResponses

    private let app = StoreApp(id: "6450000001", name: "Lumen Journal", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")

    private func loader(_ transport: FakeHTTPTransport) -> StorePageContentLoader {
        StorePageContentLoader(client: AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport))
    }

    @Test func readsVersionsAppInfoAndBothLocalizationLevels() async throws {
        let transport = FakeHTTPTransport(Canned.lumen)
        let content = try await loader(transport).content(for: app, versionID: nil)

        #expect(transport.requests.map { $0.url?.path() } == [
            "/v1/apps/6450000001/appStoreVersions",
            "/v1/apps/6450000001/appInfos",
            "/v1/appInfos/info-next/appInfoLocalizations",
            "/v1/appStoreVersions/v14/appStoreVersionLocalizations",
        ])
        #expect(transport.requests.allSatisfy { $0.httpMethod == "GET" })
        #expect(content.versions.map(\.id) == ["v14", "v13"])
        #expect(content.version.id == "v14")
        #expect(content.version.state == .prepareForSubmission)
        #expect(content.primaryLocale == .englishUS)
        #expect(content.locales == [.englishUS, .german])
        #expect(content.texts[.englishUS]?[.subtitle] == "Private notes, gentle prompts")
        #expect(content.texts[.englishUS]?[.keywords] == "diary,mood")
        #expect(content.texts[.german]?[.keywords] == nil)
        #expect(content.texts[.german]?[.privacyPolicyURL] == nil)
        #expect(content.ids == ListingResourceIDs(
            versionID: "v14",
            appInfoID: "info-next",
            versionLocalizations: [.englishUS: "vl-en", .german: "vl-de"],
            appInfoLocalizations: [.englishUS: "il-en", .german: "il-de"]
        ))
    }

    @Test func aChosenVersionIsLoaded() async throws {
        var responses = Canned.lumen
        responses[3] = Canned.page([Canned.versionLocalization("vl13-en", locale: "en-US", description: "Old text.")])
        let transport = FakeHTTPTransport(responses)
        let content = try await loader(transport).content(for: app, versionID: "v13")
        #expect(content.version.id == "v13")
        #expect(!content.version.isEditable)
        #expect(transport.requests.last?.url?.path() == "/v1/appStoreVersions/v13/appStoreVersionLocalizations")
        #expect(content.editableVersion?.id == "v14")
    }

    @Test func pagesAreFollowed() async throws {
        var responses = Canned.lumen
        let next = "https://api.appstoreconnect.apple.com/v1/appStoreVersions/v14/appStoreVersionLocalizations?cursor=Mg"
        responses[3] = Canned.page([Canned.versionLocalization("vl-en", locale: "en-US", description: "One")], next: next)
        responses.append(Canned.page([Canned.versionLocalization("vl-ja", locale: "ja", description: "二")]))
        let content = try await loader(FakeHTTPTransport(responses)).content(for: app, versionID: nil)
        #expect(content.locales.contains(.japanese))
        #expect(content.ids.versionLocalizations[.japanese] == "vl-ja")
    }

    @Test func anAppWithoutVersionsSaysSo() async {
        let transport = FakeHTTPTransport([Canned.page([])])
        await #expect(throws: AppStoreConnectError.self) {
            try await loader(transport).content(for: app, versionID: nil)
        }
    }

    @Test func theLiveAppInfoIsUsedWhenNothingIsBeingPrepared() {
        let infos: [AppStoreConnectResource<AppInfoAttributes>] = [
            AppStoreConnectResource(type: "appInfos", id: "old", attributes: AppInfoAttributes(appStoreState: nil, state: "REPLACED_WITH_NEW_INFO")),
            AppStoreConnectResource(type: "appInfos", id: "live", attributes: AppInfoAttributes(appStoreState: nil, state: "READY_FOR_DISTRIBUTION")),
        ]
        #expect(StorePageContentLoader.preferredAppInfo(in: infos)?.id == "live")
    }

    @Test func versionsWithUnknownStatesAreLeftOut() {
        let replaced = AppStoreConnectResource(
            type: "appStoreVersions",
            id: "v1",
            attributes: AppStoreVersionAttributes(versionString: "1.0", platform: "IOS", appStoreState: nil, appVersionState: "REPLACED_WITH_NEW_VERSION")
        )
        #expect(StorePageContentLoader.version(replaced, isFirstVersion: false) == nil)
    }

    /// "Add for Review" in App Store Connect moves the version to
    /// `READY_FOR_REVIEW`; the page used to drop it and say the app had no
    /// version (Alba, 2026-11-05).
    @Test func aVersionAddedForReviewOpensEditable() async throws {
        var responses = Canned.lumen
        responses[0] = Canned.page([
            Canned.version("v13", "1.3", state: "READY_FOR_DISTRIBUTION", created: "2026-08-01T09:00:00-07:00"),
            Canned.version("v14", "1.4", state: "READY_FOR_REVIEW", created: "2026-10-01T09:00:00-07:00"),
        ])
        let content = try await loader(FakeHTTPTransport(responses)).content(for: app, versionID: nil)
        #expect(content.version.id == "v14")
        #expect(content.version.state == .readyForReview)
        #expect(content.version.isEditable)
    }

    @Test(arguments: [
        "WAITING_FOR_EXPORT_COMPLIANCE", "INVALID_BINARY", "ACCEPTED", "PENDING_APPLE_RELEASE", "PROCESSING_FOR_DISTRIBUTION",
    ])
    func everyReadOnlyStateIsShown(state: String) async throws {
        var responses = Canned.lumen
        responses[0] = Canned.page([Canned.version("v14", "1.4", state: state, created: "2026-10-01T09:00:00-07:00")])
        let content = try await loader(FakeHTTPTransport(responses)).content(for: app, versionID: nil)
        #expect(content.version.state.rawValue == state)
        #expect(!content.version.isEditable)
    }

    @Test func versionsInStatesItDoesNotShowAreNamedInTheError() async {
        let transport = FakeHTTPTransport([
            Canned.page([Canned.version("v12", "1.2", state: "REPLACED_WITH_NEW_VERSION", created: "2026-05-01T09:00:00-07:00")]),
        ])
        await #expect(throws: AppStoreConnectError.notFound(
            detail: "None of its App Store versions is in a state AppLocalizer reads: 1.2 (REPLACED_WITH_NEW_VERSION)."
        )) {
            try await loader(transport).content(for: app, versionID: nil)
        }
    }

    @Test func aRateLimitIsAnError() async {
        let transport = FakeHTTPTransport([CannedHTTPResponse(statusCode: 429, body: #"{"errors":[{"status":"429","code":"RATE_LIMIT_EXCEEDED"}]}"#)])
        await #expect(throws: AppStoreConnectError.rateLimited) {
            try await loader(transport).content(for: app, versionID: nil)
        }
    }
}
