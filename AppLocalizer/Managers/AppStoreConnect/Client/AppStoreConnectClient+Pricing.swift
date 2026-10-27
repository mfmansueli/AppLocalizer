//
//  AppStoreConnectClient+Pricing.swift
//  AppLocalizer
//

import Foundation

/// The reads Subscription Pricing makes. Writes go through Review & Push as
/// `PushRequest`s, never from here.
extension AppStoreConnectClient {
    /// Most territories a single price point request asks for; keeps each
    /// response a few pages long.
    static let pricePointTerritoryBatch = 25

    /// `GET /v1/apps/{id}/subscriptionGroups?include=subscriptions`, every page.
    func pricedSubscriptionGroups(appID: String) async throws -> PricingAPIDocument<SubscriptionGroupAttributes> {
        try await pricingPages(of: "/v1/apps/\(appID)/subscriptionGroups", query: [
            URLQueryItem(name: "include", value: "subscriptions"),
            URLQueryItem(name: "fields[subscriptions]", value: "name,productId,state,subscriptionPeriod"),
            URLQueryItem(name: "limit[subscriptions]", value: "50"),
            URLQueryItem(name: "limit", value: "200"),
        ])
    }

    /// `GET /v1/apps/{id}/inAppPurchasesV2`, every page.
    func pricedInAppPurchases(appID: String) async throws -> [PricingAPIResource<InAppPurchaseAttributes>] {
        try await pricingPages(of: "/v1/apps/\(appID)/inAppPurchasesV2", query: [
            URLQueryItem(name: "fields[inAppPurchases]", value: "name,productId,inAppPurchaseType,state"),
            URLQueryItem(name: "limit", value: "200"),
        ]).data
    }

    /// `GET /v1/subscriptions/{id}/prices` with each price's point and
    /// territory, every page. `territoryID` narrows it to one territory.
    func subscriptionPrices(subscriptionID: String, territoryID: String? = nil) async throws -> PricingAPIDocument<SubscriptionPriceAttributes> {
        var query = [
            URLQueryItem(name: "include", value: "subscriptionPricePoint,territory"),
            URLQueryItem(name: "fields[subscriptionPricePoints]", value: "customerPrice,proceeds,proceedsYear2"),
            URLQueryItem(name: "fields[territories]", value: "currency"),
            URLQueryItem(name: "limit", value: "200"),
        ]
        if let territoryID { query.append(URLQueryItem(name: "filter[territory]", value: territoryID)) }
        return try await pricingPages(of: "/v1/subscriptions/\(subscriptionID)/prices", query: query)
    }

    /// `GET /v1/subscriptions/{id}/pricePoints` for a few territories: Apple's
    /// full ladder of prices there, each with the ID a price change needs.
    func subscriptionPricePoints(
        subscriptionID: String,
        territoryIDs: [String]
    ) async throws -> PricingAPIDocument<SubscriptionPricePointAttributes> {
        try await pricingPages(of: "/v1/subscriptions/\(subscriptionID)/pricePoints", query: [
            URLQueryItem(name: "filter[territory]", value: territoryIDs.joined(separator: ",")),
            URLQueryItem(name: "include", value: "territory"),
            URLQueryItem(name: "fields[subscriptionPricePoints]", value: "customerPrice,proceeds,proceedsYear2,territory"),
            URLQueryItem(name: "fields[territories]", value: "currency"),
            URLQueryItem(name: "limit", value: "8000"),
        ])
    }

    /// `GET /v1/subscriptionPricePoints/{id}/equalizations`: the point in every
    /// other territory that Apple equalizes with this one.
    func equalizations(pricePointID: String) async throws -> PricingAPIDocument<SubscriptionPricePointAttributes> {
        try await pricingPages(of: "/v1/subscriptionPricePoints/\(pricePointID)/equalizations", query: [
            URLQueryItem(name: "include", value: "territory"),
            URLQueryItem(name: "fields[subscriptionPricePoints]", value: "customerPrice,proceeds,proceedsYear2,territory"),
            URLQueryItem(name: "fields[territories]", value: "currency"),
            URLQueryItem(name: "limit", value: "200"),
        ])
    }

    /// Follows `links.next`, keeping `included` from every page.
    func pricingPages<Attributes>(of path: String, query: [URLQueryItem]) async throws -> PricingAPIDocument<Attributes> {
        var next: URL? = url(path, query: query)
        var merged = PricingAPIDocument<Attributes>(data: [], included: [])
        while let pageURL = next {
            let page: PricingAPIDocument<Attributes> = try await get(pageURL)
            merged.data += page.data
            merged.included = (merged.included ?? []) + (page.included ?? [])
            next = page.links?.next
        }
        return merged
    }
}
