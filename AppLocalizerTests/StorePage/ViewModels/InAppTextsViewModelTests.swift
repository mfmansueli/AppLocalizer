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
            productLocalizations: ["lumen.monthly": [.englishUS: "sl-en"], "lumen.lifetime": [.englishUS: "pl-en"]],
            editableVersions: [InAppTextsContent.groupKey: "gv1", "lumen.monthly": "sv1", "lumen.lifetime": "pv1"]
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
            path: "/v2/subscriptionLocalizations/sl-en",
            type: "subscriptionLocalizations",
            id: "sl-en",
            attributes: ["description": "Unlimited photos and themes"]
        )])
        #expect(change.restoreRequests.first?.path == "/v2/subscriptionLocalizations/sl-en")
        #expect(change.conflictCheck?.expected == "Unlimited photos")
        #expect(try model.isPending(column("lumen.monthly.description"), in: .englishUS))
    }

    @Test func aPurchaseNameGoesToItsLocalization() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        try model.edit(column("lumen.lifetime.name"), in: .englishUS, to: "Lumen Forever")
        #expect(queue.changes.first?.requests.first?.path == "/v2/inAppPurchaseLocalizations/pl-en")
    }

    @Test func aNewGroupLocaleIsPostedUnderTheGroup() async throws {
        let queue = ChangeQueue()
        let model = await makeModel(queue: queue)
        model.edit(.groupName, in: .german, to: "Lumen Plus")

        let change = try #require(queue.changes.first)
        #expect(change.id == "storePage.app1.inApp.group.grp.de-DE.new")
        #expect(change.requests.first?.method == .post)
        #expect(change.requests.first?.path == "/v2/subscriptionGroupLocalizations")
        let body = try #require(StorePageWriteDocument.decode(change.requests.first?.body))
        #expect(body.attribute("locale") == "de-DE")
        #expect(body.attribute("name") == "Lumen Plus")
        #expect(body.data.relationships?["version"]?.data == .init(type: "subscriptionGroupVersions", id: "gv1"))
        #expect(change.blockedReason == nil)
    }

    /// No version takes edits (none yet, or the last one is submitted): one
    /// POST per locale with every text, into a draft the push finds or
    /// makes, even where the locale exists.
    @Test func withoutAnEditableVersionTheTextsGoIntoADraft() async throws {
        let queue = ChangeQueue()
        let services = FakeStorePageServices()
        var unversioned = content
        unversioned.editableVersions = [:]
        services.inAppTextsContent = unversioned
        let model = InAppTextsViewModel(app: app, services: services, queue: queue)
        await model.load(listing: StorePageContentFixtures.editable.listing())
        try model.edit(column("lumen.monthly.description"), in: .englishUS, to: "Unlimited photos and themes")

        let change = try #require(queue.changes.first)
        #expect(change.id == "storePage.app1.inApp.product.sub1.en-US.new")
        let request = try #require(change.requests.first)
        let write = try #require(InAppDraftWrite(request))
        #expect(write.ownerKey == "subscriptions/sub1")
        #expect(write.versionsPath == "/v1/subscriptions/sub1/versions?limit=200")
        #expect(write.attributes["name"] == "Lumen Plus Monthly")
        #expect(write.update(id: "sl2").path == "/v2/subscriptionLocalizations/sl2")
        #expect(write.create(versionID: "sv2").path == "/v2/subscriptionLocalizations")
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
