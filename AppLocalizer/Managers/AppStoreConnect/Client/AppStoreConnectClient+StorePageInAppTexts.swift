//
//  AppStoreConnectClient+StorePageInAppTexts.swift
//  AppLocalizer
//

import Foundation

// The In-App Texts view's reads: subscription groups, subscriptions and
// in-app purchases with their localizations. Since API 4.4.1 the texts
// live in numbered versions (`…/versions`), each with its localizations;
// the older lists still read the current texts.
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

    // MARK: - Versions (API 4.4.1)

    /// `GET /v1/subscriptionGroups/{id}/versions`.
    func subscriptionGroupVersions(groupID: String) async throws -> [AppStoreConnectResource<InAppTextVersionAttributes>] {
        try await allPages(of: "/v1/subscriptionGroups/\(groupID)/versions", query: [Self.inAppPageLimit])
    }

    /// `GET /v1/subscriptionGroupVersions/{id}/localizations`.
    func subscriptionGroupVersionLocalizations(versionID: String) async throws -> [AppStoreConnectResource<SubscriptionGroupLocalizationAttributes>] {
        try await allPages(of: "/v1/subscriptionGroupVersions/\(versionID)/localizations", query: [Self.inAppPageLimit])
    }

    /// `GET /v1/subscriptions/{id}/versions`.
    func subscriptionVersions(subscriptionID: String) async throws -> [AppStoreConnectResource<InAppTextVersionAttributes>] {
        try await allPages(of: "/v1/subscriptions/\(subscriptionID)/versions", query: [Self.inAppPageLimit])
    }

    /// `GET /v1/subscriptionVersions/{id}/localizations`.
    func subscriptionVersionLocalizations(versionID: String) async throws -> [AppStoreConnectResource<SubscriptionLocalizationAttributes>] {
        try await allPages(of: "/v1/subscriptionVersions/\(versionID)/localizations", query: [Self.inAppPageLimit])
    }

    /// `GET /v2/inAppPurchases/{id}/versions`.
    func inAppPurchaseVersions(purchaseID: String) async throws -> [AppStoreConnectResource<InAppTextVersionAttributes>] {
        try await allPages(of: "/v2/inAppPurchases/\(purchaseID)/versions", query: [Self.inAppPageLimit])
    }

    /// `GET /v1/inAppPurchaseVersions/{id}/localizations`.
    func inAppPurchaseVersionLocalizations(versionID: String) async throws -> [AppStoreConnectResource<InAppPurchaseLocalizationAttributes>] {
        try await allPages(of: "/v1/inAppPurchaseVersions/\(versionID)/localizations", query: [Self.inAppPageLimit])
    }
}
