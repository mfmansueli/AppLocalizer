//
//  AppStoreConnectClient+StorePage.swift
//  AppLocalizer
//

import Foundation

// The Store Page's reads: versions, app infos and both kinds of
// localization. Writes are `PushRequest`s queued as pending changes.
extension AppStoreConnectClient {
    private static let pageLimit = URLQueryItem(name: "limit", value: "200")

    /// Every App Store version of the app, any platform and state
    /// (`GET /v1/apps/{id}/appStoreVersions`).
    func appStoreVersions(appID: String) async throws -> [AppStoreConnectResource<AppStoreVersionAttributes>] {
        try await allPages(of: "/v1/apps/\(appID)/appStoreVersions", query: [Self.pageLimit])
    }

    /// The app's app infos: the live one, plus one being prepared with the
    /// next version (`GET /v1/apps/{id}/appInfos`).
    func appInfos(appID: String) async throws -> [AppStoreConnectResource<AppInfoAttributes>] {
        try await allPages(of: "/v1/apps/\(appID)/appInfos", query: [Self.pageLimit])
    }

    /// Name, subtitle and privacy policy URL in every locale
    /// (`GET /v1/appInfos/{id}/appInfoLocalizations`).
    func appInfoLocalizations(appInfoID: String) async throws -> [AppStoreConnectResource<AppInfoLocalizationAttributes>] {
        try await allPages(of: "/v1/appInfos/\(appInfoID)/appInfoLocalizations", query: [Self.pageLimit])
    }

    /// One version's texts in every locale
    /// (`GET /v1/appStoreVersions/{id}/appStoreVersionLocalizations`).
    func appStoreVersionLocalizations(versionID: String) async throws -> [AppStoreConnectResource<AppStoreVersionLocalizationAttributes>] {
        try await allPages(of: "/v1/appStoreVersions/\(versionID)/appStoreVersionLocalizations", query: [Self.pageLimit])
    }
}
