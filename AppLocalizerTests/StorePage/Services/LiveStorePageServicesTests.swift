//
//  LiveStorePageServicesTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The live services' summary, in-app texts and screenshots against canned
/// App Store Connect JSON.
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

    @Test func screenshotsAreCountedPerDeviceFromEachLocalesSets() async throws {
        let transport = FakeHTTPTransport([
            Canned.page([
                Canned.screenshotSet("s1", displayType: "APP_IPHONE_67", screenshots: 6),
                Canned.screenshotSet("s2", displayType: "APP_IPHONE_61", screenshots: 3),
                Canned.screenshotSet("s3", displayType: "APP_DESKTOP", screenshots: 4),
                Canned.screenshotSet("s4", displayType: "APP_WATCH_ULTRA", screenshots: 2),
            ]),
            Canned.page([Canned.screenshotSet("s5", displayType: "APP_IPAD_PRO_3GEN_129", screenshots: 5)]),
        ])
        let content = StorePageContent(
            appName: "Lumen Journal",
            primaryLocale: .englishUS,
            versions: [],
            version: StorePageContentFixtures.editableVersion,
            locales: [.englishUS, .german],
            texts: [:],
            ids: ListingResourceIDs(versionID: "v14", appInfoID: "info", versionLocalizations: [.englishUS: "vl-en", .german: "vl-de"])
        )
        let coverage = try await services(transport).screenshots(for: app, content: content)

        #expect(transport.requests.map { $0.url?.path() } == [
            "/v1/appStoreVersionLocalizations/vl-en/appScreenshotSets",
            "/v1/appStoreVersionLocalizations/vl-de/appScreenshotSets",
        ])
        let query = transport.requests.first?.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        #expect(query.contains(URLQueryItem(name: "include", value: "appScreenshots")))
        #expect(coverage.count(for: .englishUS, on: .iPhone) == 6)
        #expect(coverage.count(for: .englishUS, on: .mac) == 4)
        #expect(coverage.status(for: .german, on: .iPhone) == .usesPrimary(.englishUS))
        #expect(coverage.status(for: .german, on: .iPad) == .present(count: 5))
    }

    @Test func inAppTextsReadTheGroupSubscriptionsAndPurchases() async throws {
        let transport = FakeHTTPTransport([
            Canned.page([Canned.named("subscriptionGroups", "grp", #""referenceName":"Lumen Plus""#)]),
            Canned.page([Canned.named("subscriptionGroupLocalizations", "gl-en", #""locale":"en-US","name":"Lumen Plus""#)]),
            Canned.page([Canned.named("subscriptions", "sub1", #""name":"Monthly","productId":"lumen.monthly""#)]),
            Canned.page([
                Canned.named("subscriptionLocalizations", "sl-en", #""locale":"en-US","name":"Lumen Plus Monthly","description":"Unlimited photos""#),
                Canned.named("subscriptionLocalizations", "sl-de", #""locale":"de-DE","name":"Lumen Plus monatlich","description":null"#),
            ]),
            Canned.page([Canned.named("inAppPurchases", "iap1", #""name":"Lifetime","productId":"lumen.lifetime""#)]),
            Canned.page([Canned.named("inAppPurchaseLocalizations", "pl-en", #""locale":"en-US","name":"Lumen Lifetime","description":"Forever""#)]),
        ])
        let content = try await services(transport).inAppTexts(for: app)

        #expect(transport.requests.map { $0.url?.path() } == [
            "/v1/apps/6450000001/subscriptionGroups",
            "/v1/subscriptionGroups/grp/subscriptionGroupLocalizations",
            "/v1/subscriptionGroups/grp/subscriptions",
            "/v1/subscriptions/sub1/subscriptionLocalizations",
            "/v1/apps/6450000001/inAppPurchasesV2",
            "/v2/inAppPurchases/iap1/inAppPurchaseLocalizations",
        ])
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
