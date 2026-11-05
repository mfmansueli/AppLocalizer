//
//  PricingViewModel+NewSubscription.swift
//  AppLocalizer
//

import Foundation

/// Create Subscription and Set Starting Price: both queue a change in
/// Review & Push, which creates the subscription or sets its first prices
/// when the person pushes.
extension PricingViewModel {
    var newSubscriptionBuilder: NewSubscriptionChangeBuilder {
        NewSubscriptionChangeBuilder(app: app)
    }

    /// New subscriptions of this app waiting in Review & Push.
    var queuedNewSubscriptions: [PendingChange] {
        NewSubscriptionChangeBuilder.queued(in: queue, appID: app.id)
    }

    /// The app's subscription groups, for the group picker.
    var subscriptionGroups: [PricingProductGroup] {
        catalog?.groups.filter { !$0.isInAppPurchases } ?? []
    }

    /// What Create Subscription starts with: the app's first group, or a
    /// new "Bruma Premium"; a monthly subscription named after it, with a
    /// product ID under the bundle ID.
    func newSubscriptionDefaults() -> NewSubscription {
        let short = NewSubscription.shortName(of: app.name)
        let groupName = String(localized: "\(short) Premium")
        let group = subscriptionGroups.first.map { NewSubscriptionGroup.existing(id: $0.id, referenceName: $0.name) }
            ?? .new(referenceName: groupName, displayName: groupName)
        let period = SubscriptionPeriod.oneMonth
        let locale = app.primaryLocale.flatMap(StoreLocaleCatalog.locale(code:)) ?? .englishUS
        return NewSubscription(
            group: group,
            referenceName: "\(group.referenceName) \(period.shortTitle)",
            productID: Self.suggestedProductID(bundleID: app.bundleID, period: period),
            period: period,
            locale: locale,
            displayName: "\(group.referenceName) \(period.shortTitle)",
            description: ""
        )
    }

    /// `com.lima.bruma.premium.monthly`.
    static func suggestedProductID(bundleID: String, period: SubscriptionPeriod) -> String {
        "\(bundleID).premium.\(NewSubscription.productIDSuffix(for: period))"
    }

    /// What App Store Connect would refuse, given the app's products and
    /// the other new subscriptions in Review & Push.
    func problems(for subscription: NewSubscription) -> [NewSubscriptionProblem] {
        let ownID = NewSubscriptionChangeBuilder.changeID(appID: app.id, productID: NewSubscription.trimmed(subscription.productID))
        let taken = NewSubscriptionChangeBuilder.takenProductIDs(appID: app.id, catalog: catalog, queue: queue, except: ownID)
        return subscription.problems(takenProductIDs: taken, groupNames: subscriptionGroups.map(\.name))
    }

    /// Create Subscription's Add to Review & Push.
    func queueNewSubscription(_ subscription: NewSubscription) {
        let change = newSubscriptionBuilder.change(for: subscription, problems: problems(for: subscription), at: today())
        queue.upsert(change)
        isNewSubscriptionSheetPresented = false
    }

    func discardNewSubscription(id: PendingChange.ID) {
        queue.discard(id: id)
    }

    /// Set Starting Price's change for the selected subscription, if one is
    /// waiting.
    var queuedStartingPrice: PendingChange? {
        guard let product = selectedProduct else { return nil }
        return queue.change(id: NewSubscriptionChangeBuilder.startingPriceChangeID(appID: app.id, productID: product.productID))
    }

    /// Set Starting Price's Add to Review & Push.
    func queueStartingPrice(_ price: Decimal) {
        guard let product = selectedProduct else { return }
        queue.upsert(newSubscriptionBuilder.startingPriceChange(for: product, price: price, at: today()))
        isStartingPriceSheetPresented = false
    }
}
