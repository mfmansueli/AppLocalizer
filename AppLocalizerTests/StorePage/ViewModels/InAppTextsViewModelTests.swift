//
//  InAppTextsViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// In-App Texts: cells edited, queued with their writes, and reverted when
/// discarded in review.
@MainActor
@Suite("InAppTextsViewModel")
struct InAppTextsViewModelTests {
    private let app = StorePageContentFixtures.app
    private let monthly = InAppTextProduct(id: "lumen.monthly", referenceName: "Monthly", kind: .subscription)
    private let lifetime = InAppTextProduct(id: "lumen.lifetime", referenceName: "Lifetime", kind: .inAppPurchase)

    private var content: InAppTextsContent {
        InAppTextsContent(
            products: [monthly, lifetime],
            texts: [.englishUS: [
                "group.name": "Lumen Plus",
                "lumen.monthly.name": "Lumen Plus Monthly",
                "lumen.monthly.description": "Unlimited photos",
                "lumen.lifetime.name": "Lumen Lifetime",
            ]],
            groupID: "grp",
            groupLocalizations: [.englishUS: "gl-en"],
            productResourceIDs: ["lumen.monthly": "sub1", "lumen.lifetime": "iap1"],
            productLocalizations: ["lumen.monthly": [.englishUS: "sl-en"], "lumen.lifetime": [.englishUS: "pl-en"]]
        )
    }

    private func column(_ id: String) throws -> InAppTextColumn {
        try #require(InAppTextColumn.columns(for: [monthly, lifetime]).first { $0.id == id })
    }

    private func makeModel(queue: ChangeQueue) async -> InAppTextsViewModel {
        let services = FakeStorePageServices()
        services.inAppTextsContent = content
        let model = InAppTextsViewModel(app: app, services: services, queue: queue)
        await model.load(listing: StorePageContentFixtures.editable.listing())
        return model
    }

    @Test func listsTheStorePagesLocales() async throws {
        let model = await makeModel(queue: ChangeQueue())
        #expect(model.matrix?.displayLocales == [.englishUS, .german])
        #expect(try model.value(column("lumen.monthly.name"), in: .englishUS) == "Lumen Plus Monthly")
        #expect(try model.counter(column("lumen.monthly.name"), in: .englishUS).text == "18 / 30")
    }

    @Test func editingAnExistingLocalizationPatchesIt() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        try model.edit(column("lumen.monthly.description"), in: .englishUS, to: "Unlimited photos and themes")

        let change = try #require(queue.changes.first)
        #expect(change.id == "storePage.app1.inApp.product.sub1.en-US.description")
        #expect(change.group == "Store Page · In-App Texts")
        #expect(change.requests == [ListingChangeBuilder.patch(
            path: "/v1/subscriptionLocalizations/sl-en",
            type: "subscriptionLocalizations",
            id: "sl-en",
            attributes: ["description": "Unlimited photos and themes"]
        )])
        #expect(change.restoreRequests.first?.path == "/v1/subscriptionLocalizations/sl-en")
        #expect(change.conflictCheck?.expected == "Unlimited photos")
        #expect(try model.isPending(column("lumen.monthly.description"), in: .englishUS))
    }

    @Test func aPurchaseNameGoesToItsLocalization() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        try model.edit(column("lumen.lifetime.name"), in: .englishUS, to: "Lumen Forever")
        #expect(queue.changes.first?.requests.first?.path == "/v1/inAppPurchaseLocalizations/pl-en")
    }

    @Test func aNewGroupLocaleIsPostedUnderTheGroup() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.edit(.groupName, in: .german, to: "Lumen Plus")

        let change = try #require(queue.changes.first)
        #expect(change.id == "storePage.app1.inApp.group.grp.de-DE.new")
        #expect(change.requests.first?.method == .post)
        #expect(change.requests.first?.path == "/v1/subscriptionGroupLocalizations")
        let body = try #require(StorePageWriteDocument.decode(change.requests.first?.body))
        #expect(body.attribute("locale") == "de-DE")
        #expect(body.attribute("name") == "Lumen Plus")
        #expect(body.data.relationships?["subscriptionGroup"]?.data.id == "grp")
        #expect(change.blockedReason == nil)
    }

    @Test func aNewLocaleNeedsANameFirst() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        try model.edit(column("lumen.monthly.description"), in: .german, to: "Unbegrenzt Fotos")
        #expect(queue.changes.first?.blockedReason?.hasPrefix("Add a display name first") == true)
    }

    @Test func overTheLimitIsBlocked() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        try model.edit(column("lumen.monthly.description"), in: .englishUS, to: String(repeating: "d", count: 46))
        #expect(queue.changes.first?.blockedReason != nil)
        #expect(try model.counter(column("lumen.monthly.description"), in: .englishUS).isOverLimit)
    }

    @Test func discardingInReviewRevertsTheCell() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        try model.edit(column("lumen.lifetime.name"), in: .englishUS, to: "Lumen Forever")
        queue.discardAll { _ in true }
        model.queueDidChange()
        #expect(try model.value(column("lumen.lifetime.name"), in: .englishUS) == "Lumen Lifetime")
    }

    @Test func typingTheOldTextBackRemovesTheChange() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        let name = try column("lumen.lifetime.name")
        model.edit(name, in: .englishUS, to: "Lumen Forever")
        model.edit(name, in: .englishUS, to: "Lumen Lifetime")
        #expect(queue.changes.isEmpty)
    }
}
