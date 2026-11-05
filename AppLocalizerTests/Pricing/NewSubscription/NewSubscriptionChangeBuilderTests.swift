//
//  NewSubscriptionChangeBuilderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A new subscription as one Review & Push change: its checks, its
/// requests in order, and the creation row.
@Suite("NewSubscriptionChangeBuilder")
struct NewSubscriptionChangeBuilderTests {
    static let app = StoreApp(id: "app1", name: "Bruma – Gay Dating Nearby", bundleID: "com.lima.bruma", primaryLocale: "en-US")

    static func monthly(group: NewSubscriptionGroup = .new(referenceName: "Bruma Premium", displayName: "Bruma Premium")) -> NewSubscription {
        NewSubscription(
            group: group,
            referenceName: "Bruma Premium Monthly",
            productID: "com.lima.bruma.premium.monthly",
            period: .oneMonth,
            locale: .englishUS,
            displayName: "Bruma Premium",
            description: "See who likes you",
            price: Decimal(string: "9.99")
        )
    }

    private func json(_ request: PushRequest?) throws -> [String: Any] {
        let body = try #require(request?.body)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    private func data(_ request: PushRequest?) throws -> [String: Any] {
        try #require(json(request)["data"] as? [String: Any])
    }

    // MARK: - Checks

    @Test func aCompleteSubscriptionHasNoProblems() {
        #expect(Self.monthly().problems(takenProductIDs: [], groupNames: []).isEmpty)
    }

    @Test func everyMissingFieldIsNamed() {
        let empty = NewSubscription(
            group: .new(referenceName: "", displayName: ""),
            referenceName: "",
            productID: "",
            period: .oneYear,
            locale: .englishUS,
            displayName: "",
            description: ""
        )
        #expect(empty.problems(takenProductIDs: [], groupNames: []) == [
            .missing(.groupReferenceName), .missing(.groupDisplayName), .missing(.referenceName), .missing(.productID),
            .missing(.displayName), .missing(.description), .missing(.price),
        ])
    }

    @Test func aTakenOrMalformedProductIDIsRefused() {
        var subscription = Self.monthly()
        let taken = subscription.problems(takenProductIDs: ["COM.LIMA.BRUMA.PREMIUM.MONTHLY"], groupNames: [])
        #expect(taken == [.productIDTaken("com.lima.bruma.premium.monthly")])
        subscription.productID = "com.lima.bruma/premium monthly"
        #expect(subscription.problems(takenProductIDs: [], groupNames: []) == [.invalidProductID])
    }

    @Test func overTheLimitTextsAreCounted() {
        var subscription = Self.monthly()
        subscription.displayName = String(repeating: "a", count: 31)
        subscription.description = String(repeating: "b", count: 46)
        #expect(subscription.problems(takenProductIDs: [], groupNames: []) == [.tooLong(.displayName, count: 31), .tooLong(.description, count: 46)])
    }

    @Test func aNewGroupNamedLikeAnExistingOneIsRefused() {
        #expect(Self.monthly().problems(takenProductIDs: [], groupNames: ["bruma premium"]) == [.groupExists("bruma premium")])
    }

    @Test func pricesNeedTwoDecimalsAtMost() throws {
        #expect(NewSubscription.price(from: "$9,99") == Decimal(string: "9.99"))
        #expect(NewSubscription.price(from: "abc") == nil)
        let tooPrecise = try #require(Decimal(string: "9.999"))
        #expect(NewSubscription.isValidPrice(tooPrecise) == false)
        #expect(NewSubscription.isValidPrice(0) == false)
    }

    @Test func theShortNameDropsWhatFollowsADash() {
        #expect(NewSubscription.shortName(of: "Bruma – Gay Dating Nearby") == "Bruma")
        #expect(NewSubscription.shortName(of: "Alba: Daily Motivation") == "Alba")
        #expect(NewSubscription.shortName(of: "Lumen Journal") == "Lumen Journal")
    }

    // MARK: - Requests

    @Test func aNewGroupIsFoundOrCreatedAndGetsItsName() throws {
        let change = NewSubscriptionChangeBuilder(app: Self.app).change(for: Self.monthly())
        let group = SubscriptionGroupPlaceholder.placeholder(appID: "app1", referenceName: "Bruma Premium")
        #expect(change.requests.map(\.path) == [
            "/v1/subscriptions", "/v2/subscriptionGroupLocalizations", "/v2/subscriptionLocalizations",
            "/v1/subscriptionAvailabilities", "/v1/subscriptionPrices",
        ])

        let create = try data(change.requests[0])
        let attributes = try #require(create["attributes"] as? [String: Any])
        #expect(attributes["productId"] as? String == "com.lima.bruma.premium.monthly")
        #expect(attributes["subscriptionPeriod"] as? String == "ONE_MONTH")
        #expect(attributes["familySharable"] as? Bool == false)
        #expect(attributes["reviewNote"] == nil)
        let groupLink = (create["relationships"] as? [String: Any])?["group"] as? [String: Any]
        #expect((groupLink?["data"] as? [String: Any])?["id"] as? String == group)

        let groupName = try #require(StorePageWriteDocument.decode(change.requests[1].body))
        #expect(groupName.attribute("name") == "Bruma Premium")
        #expect(groupName.data.relationships?["version"]?.data.id == PushRequest.inAppDraftPlaceholder(ownerType: "subscriptionGroups", ownerID: group))

        let texts = try #require(StorePageWriteDocument.decode(change.requests[2].body))
        #expect(texts.attribute("description") == "See who likes you")
        #expect(texts.data.relationships?["version"]?.data.id == "{inAppDraft:subscriptions/{createdID:subscriptions}}")

        let availability = try data(change.requests[3])
        let territories = ((availability["relationships"] as? [String: Any])?["availableTerritories"] as? [String: Any])?["data"] as? [[String: Any]]
        // Every territory App Store Connect has, read when it's sent.
        #expect(territories?.compactMap { $0["id"] as? String } == [SubscriptionAvailabilityEverywhere.placeholder])
        #expect(SubscriptionAvailabilityEverywhere(change.requests[3])?.subscriptionID == "{createdID:subscriptions}")

        let prices = try #require(SubscriptionStartingPrices(change.requests[4]))
        #expect(prices.subscriptionID == "{createdID:subscriptions}")
        #expect(prices.territoryID == "USA")
        #expect(prices.customerPrice == Decimal(string: "9.99"))
    }

    @Test func anExistingGroupIsNamedByIDAndKeepsItsTexts() throws {
        let change = NewSubscriptionChangeBuilder(app: Self.app).change(for: Self.monthly(group: .existing(id: "grp1", referenceName: "Bruma Premium")))
        #expect(change.requests.map(\.path) == [
            "/v1/subscriptions", "/v2/subscriptionLocalizations", "/v1/subscriptionAvailabilities", "/v1/subscriptionPrices",
        ])
        let group = try (data(change.requests[0])["relationships"] as? [String: Any])?["group"] as? [String: Any]
        #expect((group?["data"] as? [String: Any])?["id"] as? String == "grp1")
    }

    @Test func theChangeIsACreationRowWithItsFields() throws {
        var subscription = Self.monthly()
        subscription.reviewNote = "Settings → Premium"
        let change = NewSubscriptionChangeBuilder(app: Self.app).change(
            for: subscription,
            problems: [.missing(.price)],
            source: .assistant(client: "Claude Code"),
            evidence: ["Bruma/Store.swift:12 — buys it"]
        )
        #expect(change.id == "subscriptionSetup.app1.com.lima.bruma.premium.monthly")
        #expect(change.section == .subscriptionPricing)
        #expect(change.title == "Bruma Premium Monthly")
        #expect(change.newValue == "1 month · $9.99")
        #expect(change.blockedReason == NewSubscriptionProblem.missing(.price).message)
        #expect(change.restoreRequests.isEmpty)
        let creation = try #require(change.creation)
        #expect(creation.title == "Create Bruma Premium Monthly")
        #expect(creation.source == .assistant(client: "Claude Code"))
        #expect(creation.fields.map(\.id) == [
            "productId", "group", "groupName", "period", "name", "description", "price", "familySharing", "reviewNote", "evidence",
        ])
        #expect(NewSubscriptionChangeBuilder.productID(of: change) == "com.lima.bruma.premium.monthly")
        #expect(NewSubscriptionChangeBuilder.owns(change))
    }

    @Test func aStartingPriceForAnExistingSubscriptionUsesItsID() throws {
        let product = PricingProduct(
            id: "sub9",
            name: "Bruma Annual",
            productID: "com.lima.bruma.annual",
            period: .oneYear,
            isInAppPurchase: false,
            reviewState: "Missing Metadata"
        )
        let change = try NewSubscriptionChangeBuilder(app: Self.app).startingPriceChange(for: product, price: #require(Decimal(string: "59.99")))
        #expect(change.id == "subscriptionSetup.app1.com.lima.bruma.annual.startingPrice")
        #expect(change.blockedReason == nil)
        let request = try #require(change.requests.first)
        let prices = try #require(SubscriptionStartingPrices(request))
        #expect(prices.subscriptionID == "sub9")
    }
}
