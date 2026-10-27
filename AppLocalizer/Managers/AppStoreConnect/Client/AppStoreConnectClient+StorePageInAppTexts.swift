//
//  AppStoreConnectClient+StorePageInAppTexts.swift
//  AppLocalizer
//

import Foundation

// The In-App Texts view's reads: subscription groups, subscriptions and
// in-app purchases with their localizations.
extension AppStoreConnectClient {
    private static let inAppPageLimit = URLQueryItem(name: "limit", value: "200")

    /// `GET /v1/apps/{id}/subscriptionGroups`.
    func subscriptionGroups(appID: String) async throws -> [AppStoreConnectResource<SubscriptionGroupAttributes>] {
        try await allPages(of: "/v1/apps/\(appID)/subscriptionGroups", query: [Self.inAppPageLimit])
    }

    /// `GET /v1/subscriptionGroups/{id}/subscriptionGroupLocalizations`.
    func subscriptionGroupLocalizations(groupID: String) async throws -> [AppStoreConnectResource<SubscriptionGroupLocalizationAttributes>] {
        try await allPages(of: "/v1/subscriptionGroups/\(groupID)/subscriptionGroupLocalizations", query: [Self.inAppPageLimit])
    }

    /// `GET /v1/subscriptionGroups/{id}/subscriptions`.
    func subscriptions(groupID: String) async throws -> [AppStoreConnectResource<SubscriptionAttributes>] {
        try await allPages(of: "/v1/subscriptionGroups/\(groupID)/subscriptions", query: [Self.inAppPageLimit])
    }

    /// `GET /v1/subscriptions/{id}/subscriptionLocalizations`.
    func subscriptionLocalizations(subscriptionID: String) async throws -> [AppStoreConnectResource<SubscriptionLocalizationAttributes>] {
        try await allPages(of: "/v1/subscriptions/\(subscriptionID)/subscriptionLocalizations", query: [Self.inAppPageLimit])
    }

    /// `GET /v1/apps/{id}/inAppPurchasesV2`.
    func inAppPurchases(appID: String) async throws -> [AppStoreConnectResource<InAppPurchaseAttributes>] {
        try await allPages(of: "/v1/apps/\(appID)/inAppPurchasesV2", query: [Self.inAppPageLimit])
    }

    /// `GET /v2/inAppPurchases/{id}/inAppPurchaseLocalizations`.
    func inAppPurchaseLocalizations(purchaseID: String) async throws -> [AppStoreConnectResource<InAppPurchaseLocalizationAttributes>] {
        try await allPages(of: "/v2/inAppPurchases/\(purchaseID)/inAppPurchaseLocalizations", query: [Self.inAppPageLimit])
    }
}
