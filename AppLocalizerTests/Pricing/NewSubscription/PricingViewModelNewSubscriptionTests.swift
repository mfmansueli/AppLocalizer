//
//  PricingViewModelNewSubscriptionTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Create Subscription and Set Starting Price in Pricing: the suggested
/// subscription, the checks against what the app has, and the queue.
@MainActor
@Suite("Pricing · new subscriptions")
struct PricingViewModelNewSubscriptionTests {
    private let queue = ChangeQueue()

    private func model(for app: StoreApp, services: DebugPricingServices = DebugPricingServices()) async -> PricingViewModel {
        let model = PricingViewModel(app: app, services: services, queue: queue, modes: PricingModeStore(defaults: nil), commission: .smallBusiness)
        await model.load()
        return model
    }

    private static let quiet = StoreApp(
        id: DebugFixtures.AppID.quiet,
        name: "Quiet Timer – Focus Sounds",
        bundleID: "dev.northpier.quiet",
        primaryLocale: "en-US"
    )

    @Test func anAppWithoutSubscriptionsStartsANewGroup() async {
        let model = await model(for: Self.quiet)
        #expect(model.catalog?.isEmpty == true)
        let defaults = model.newSubscriptionDefaults()
        #expect(defaults.group == .new(referenceName: "Quiet Timer Premium", displayName: "Quiet Timer Premium"))
        #expect(defaults.referenceName == "Quiet Timer Premium Monthly")
        #expect(defaults.productID == "dev.northpier.quiet.premium.monthly")
        #expect(defaults.period == .oneMonth)
        #expect(defaults.locale == .englishUS)
    }

    @Test func anAppWithAGroupSuggestsIt() async throws {
        let model = await model(for: PricingModelFixtures.app)
        let group = try #require(model.subscriptionGroups.first)
        #expect(model.newSubscriptionDefaults().group == .existing(id: group.id, referenceName: group.name))
    }

    @Test func queuingShowsItAndDiscardingRemovesIt() async throws {
        let model = await model(for: Self.quiet)
        model.isNewSubscriptionSheetPresented = true
        var subscription = model.newSubscriptionDefaults()
        subscription.description = "Every sound"
        subscription.price = Decimal(string: "2.99")
        model.queueNewSubscription(subscription)

        #expect(!model.isNewSubscriptionSheetPresented)
        let queued = try #require(model.queuedNewSubscriptions.first)
        #expect(queued.blockedReason == nil)
        #expect(model.pendingPriceChangeCount == 0)

        // The same product ID again replaces it; another spelling of it is taken.
        var renamed = subscription
        renamed.referenceName = "Quiet Timer Premium Monthly Plan"
        #expect(model.problems(for: renamed).isEmpty)
        model.queueNewSubscription(renamed)
        #expect(model.queuedNewSubscriptions.map(\.title) == ["Quiet Timer Premium Monthly Plan"])
        var shouting = subscription
        shouting.productID = subscription.productID.uppercased()
        #expect(model.problems(for: shouting) == [.productIDTaken(shouting.productID)])

        model.discardNewSubscription(id: queued.id)
        #expect(model.queuedNewSubscriptions.isEmpty)
    }

    @Test func keepMyPricesLeavesNewSubscriptionsQueued() async {
        let model = await model(for: Self.quiet)
        var subscription = model.newSubscriptionDefaults()
        subscription.description = "Every sound"
        subscription.price = Decimal(string: "2.99")
        model.queueNewSubscription(subscription)
        model.confirmKeepPrices()
        #expect(model.queuedNewSubscriptions.count == 1)
    }

    @Test func aSubscriptionWithoutAPriceOffersAStartingPrice() async throws {
        var services = DebugPricingServices()
        services.sheetError = PricingSheetError.noStartingPrice(productName: "Lumen Plus Monthly")
        let model = await model(for: PricingModelFixtures.app, services: services)
        #expect(model.needsStartingPrice)

        try model.queueStartingPrice(#require(Decimal(string: "4.99")))
        let change = try #require(model.queuedStartingPrice)
        #expect(change.newValue.hasPrefix("$4.99"))
        let request = try #require(change.requests.first)
        #expect(SubscriptionStartingPrices(request)?.subscriptionID == model.selectedProduct?.id)
    }
}
#endif
