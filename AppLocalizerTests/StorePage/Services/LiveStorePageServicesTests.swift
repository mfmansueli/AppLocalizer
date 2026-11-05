//
//  LiveStorePageServicesTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The live services' summary and in-app texts against canned App Store
/// Connect JSON.
@MainActor
@Suite("LiveStorePageServices")
struct LiveStorePageServicesTests {
    private typealias Canned = StorePageCannedResponses

    private let app = StoreApp(id: "6450000001", name: "Lumen Journal", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")

    private func services(_ transport: FakeHTTPTransport, store: InMemoryMachineTranslationStore = InMemoryMachineTranslationStore()) -> LiveStorePageServices {
        LiveStorePageServices(
            client: AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport),
            machineTranslations: store,
            translator: FakeListingTranslator()
        )
    }

    @Test func theSummaryCountsTheEditableVersion() async throws {
        let summary = try await services(FakeHTTPTransport(Canned.lumen)).summary(for: app)
        #expect(summary.versionString == "1.4")
        #expect(summary.versionState == "Prepare for Submission")
        #expect(summary.hasEditableVersion)
        #expect(summary.localeCount == 2)
        #expect(summary.machineTranslatedCount == 0)
        #expect(summary.overLimitCount == 0)
        #expect(summary.missingCount > 0)
    }

    @Test func theSummaryCountsThisMacsMachineTranslationTags() async throws {
        let store = InMemoryMachineTranslationStore()
        store.setTags(["en-US.keywords": "diary,mood"], appID: app.id, scope: MachineTranslationScope.version("v14"))
        let summary = try await services(FakeHTTPTransport(Canned.lumen), store: store).summary(for: app)
        #expect(summary.machineTranslatedCount == 1)
    }

    @Test func inAppTextsReadTheGroupSubscriptionsAndPurchases() async throws {
        let transport = FakeHTTPTransport([
            Canned.page([Canned.named("subscriptionGroups", "grp", #""referenceName":"Lumen Plus""#)]),
            Canned.page([Canned.named("subscriptionGroupVersions", "gv1", #""version":1,"state":"APPROVED""#)]),
            Canned.page([Canned.named("subscriptionGroupLocalizations", "gl-en", #""locale":"en-US","name":"Lumen Plus""#)]),
            Canned.page([Canned.named("subscriptions", "sub1", #""name":"Monthly","productId":"lumen.monthly""#)]),
            Canned.page([Canned.named("subscriptionVersions", "sv2", #""version":2,"state":"PREPARE_FOR_SUBMISSION""#)]),
            Canned.page([
                Canned.named("subscriptionLocalizations", "sl-en", #""locale":"en-US","name":"Lumen Plus Monthly","description":"Unlimited photos""#),
                Canned.named("subscriptionLocalizations", "sl-de", #""locale":"de-DE","name":"Lumen Plus monatlich","description":null"#),
            ]),
            Canned.page([Canned.named("inAppPurchases", "iap1", #""name":"Lifetime","productId":"lumen.lifetime""#)]),
            CannedHTTPResponse(statusCode: 404, body: #"{"errors":[{"status":"404","code":"NOT_FOUND"}]}"#),
            Canned.page([Canned.named("inAppPurchaseLocalizations", "pl-en", #""locale":"en-US","name":"Lumen Lifetime","description":"Forever""#)]),
        ])
        let content = try await services(transport).inAppTexts(for: app)

        #expect(transport.requests.map { $0.url?.path() } == [
            "/v1/apps/6450000001/subscriptionGroups",
            "/v1/subscriptionGroups/grp/versions",
            "/v1/subscriptionGroups/grp/subscriptionGroupLocalizations",
            "/v1/subscriptionGroups/grp/subscriptions",
            "/v1/subscriptions/sub1/versions",
            "/v1/subscriptionVersions/sv2/localizations",
            "/v1/apps/6450000001/inAppPurchasesV2",
            "/v2/inAppPurchases/iap1/versions",
            "/v2/inAppPurchases/iap1/inAppPurchaseLocalizations",
        ])
        // The group's only version is approved: its draft is made on push.
        #expect(content.editableVersions == ["lumen.monthly": "sv2"])
        #expect(content.legacyOwners == ["lumen.lifetime"])
        #expect(content.groupID == "grp")
        #expect(content.products.map(\.id) == ["lumen.monthly", "lumen.lifetime"])
        #expect(content.products.map(\.kind) == [.subscription, .inAppPurchase])
        #expect(content.productResourceIDs == ["lumen.monthly": "sub1", "lumen.lifetime": "iap1"])
        #expect(content.texts[.englishUS]?["group.name"] == "Lumen Plus")
        #expect(content.texts[.german]?["lumen.monthly.name"] == "Lumen Plus monatlich")
        #expect(content.texts[.german]?["lumen.monthly.description"] == nil)
        #expect(content.localizationID(productID: "lumen.monthly", locale: .german) == "sl-de")
        #expect(content.localizationID(productID: nil, locale: .englishUS) == "gl-en")
        #expect(content.localizationID(productID: nil, locale: .german) == nil)
    }

    @Test func anAppWithoutSubscriptionsOrPurchasesIsEmpty() async throws {
        let transport = FakeHTTPTransport([Canned.page([]), Canned.page([])])
        let content = try await services(transport).inAppTexts(for: app)
        #expect(content.isEmpty)
    }
}
