//
//  AppStoreConnectClient+Apps.swift
//  AppLocalizer
//

import Foundation

extension AppStoreConnectClient {
    private static let appFields = URLQueryItem(name: "fields[apps]", value: "name,bundleId,sku,primaryLocale")

    /// Every app the key's team can see, sorted by name (`GET /v1/apps`).
    func apps() async throws -> [StoreApp] {
        let resources: [AppStoreConnectResource<AppAttributes>] = try await allPages(of: "/v1/apps", query: [
            Self.appFields,
            URLQueryItem(name: "sort", value: "name"),
            URLQueryItem(name: "limit", value: "200"),
        ])
        return resources.map(StoreApp.init)
    }

    /// The cheapest call that proves the key works: one app, one field set.
    /// Throws `.unauthorized` for a wrong issuer/key pair.
    func verifyAccess() async throws {
        let _: AppStoreConnectPage<AppAttributes> = try await get(url("/v1/apps", query: [
            Self.appFields,
            URLQueryItem(name: "limit", value: "1"),
        ]))
    }
}
