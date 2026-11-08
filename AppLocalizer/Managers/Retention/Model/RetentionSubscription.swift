//
//  RetentionSubscription.swift
//  AppLocalizer
//

import Foundation

/// A subscription a retention message can cover, from Pricing's catalog.
/// A subscription shows at most one message.
struct RetentionSubscription: Identifiable, Hashable, Sendable {
    /// App Store Connect's resource ID.
    var id: String
    /// "Lumen Plus Monthly".
    var name: String
    var productID: String
    var period: SubscriptionPeriod?
    /// The usual price in the United States.
    var basePrice: Decimal?
    /// "Lumen Plus", the group's name.
    var groupName: String

    /// "Monthly": the name without the group's, else the period's.
    var shortName: String {
        let trimmed = name.hasPrefix(groupName) ? name.dropFirst(groupName.count).trimmingCharacters(in: .whitespaces) : ""
        if !trimmed.isEmpty { return trimmed }
        return period?.shortTitle ?? name
    }

    /// The subscriptions in Pricing's catalog, without in-app purchases.
    static func all(in catalog: PricingCatalog) -> [RetentionSubscription] {
        catalog.groups.filter { !$0.isInAppPurchases }.flatMap { group in
            group.products.map { product in
                RetentionSubscription(
                    id: product.id,
                    name: product.name,
                    productID: product.productID,
                    period: product.period,
                    basePrice: product.basePrice,
                    groupName: group.name
                )
            }
        }
    }

    /// "Lumen Plus Monthly and Annual", "Lumen Plus Monthly", or "No
    /// subscription yet" for the list's second line.
    static func summary(of subscriptions: [RetentionSubscription]) -> String {
        guard let first = subscriptions.first else { return String(localized: "No subscription yet") }
        if subscriptions.count == 1 { return first.name }
        let sameGroup = subscriptions.allSatisfy { $0.groupName == first.groupName && $0.name.hasPrefix($0.groupName) }
        if sameGroup {
            let parts = subscriptions.map(\.shortName).formatted(.list(type: .and))
            return "\(first.groupName) \(parts)"
        }
        return subscriptions.map(\.name).formatted(.list(type: .and))
    }
}
