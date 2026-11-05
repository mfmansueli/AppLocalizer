//
//  StorePageContentLoader.swift
//  AppLocalizer
//

import Foundation

/// Reads one app's store page from App Store Connect: its versions, the
/// app info being prepared (else the live one), and both kinds of
/// localization for the chosen version.
struct StorePageContentLoader: Sendable {
    let client: AppStoreConnectClient

    func content(for app: StoreApp, versionID: String?) async throws -> StorePageContent {
        let versionResources = try await client.appStoreVersions(appID: app.id)
        let all = versionResources.compactMap { Self.version($0, isFirstVersion: versionResources.count == 1) }
        let versions = StorePageVersion.pickerVersions(from: all)
        guard let version = versions.first(where: { $0.id == versionID }) ?? StorePageVersion.preferred(in: versions) else {
            throw AppStoreConnectError.notFound(detail: Self.noVersionDetail(versionResources))
        }
        let appInfos = try await client.appInfos(appID: app.id)
        guard let appInfo = Self.preferredAppInfo(in: appInfos) else {
            throw AppStoreConnectError.notFound(detail: String(localized: "This app has no app information yet."))
        }
        let infoLocalizations = try await client.appInfoLocalizations(appInfoID: appInfo.id)
        let versionLocalizations = try await client.appStoreVersionLocalizations(versionID: version.id)

        let primary = app.primaryLocale.flatMap(StoreLocaleCatalog.resolve)?.locale ?? .englishUS
        var ids = ListingResourceIDs(versionID: version.id, appInfoID: appInfo.id)
        var locales: [StoreLocale] = []
        var texts: [StoreLocale: [ListingField: String]] = [:]
        for resource in infoLocalizations {
            guard let locale = StoreLocaleCatalog.locale(code: resource.attributes.locale) else { continue }
            ids.appInfoLocalizations[locale] = resource.id
            if !locales.contains(locale) { locales.append(locale) }
            texts[locale, default: [:]].merge(resource.attributes.texts) { _, new in new }
        }
        for resource in versionLocalizations {
            guard let locale = StoreLocaleCatalog.locale(code: resource.attributes.locale) else { continue }
            ids.versionLocalizations[locale] = resource.id
            if !locales.contains(locale) { locales.append(locale) }
            texts[locale, default: [:]].merge(resource.attributes.texts) { _, new in new }
        }
        return StorePageContent(
            appName: app.name,
            primaryLocale: primary,
            versions: versions,
            version: version,
            locales: locales,
            texts: texts,
            ids: ids
        )
    }

    /// Known states only: replaced or removed versions aren't edited here.
    static func version(_ resource: AppStoreConnectResource<AppStoreVersionAttributes>, isFirstVersion: Bool) -> StorePageVersion? {
        guard let state = resource.attributes.state.flatMap(ListingVersionState.init(rawValue:)) else { return nil }
        return StorePageVersion(
            id: resource.id,
            listingVersion: ListingVersion(resource.attributes.versionString, state: state, isFirstVersion: isFirstVersion),
            platform: resource.attributes.platform,
            createdDate: resource.attributes.createdDate.flatMap { try? Date($0, strategy: .iso8601) }
        )
    }

    /// Why there's no version to open: none at all, or only ones in states
    /// this page doesn't show, named so the cause is visible ("1.0
    /// (REPLACED_WITH_NEW_VERSION)") instead of "no version yet".
    static func noVersionDetail(_ resources: [AppStoreConnectResource<AppStoreVersionAttributes>]) -> String {
        guard !resources.isEmpty else { return String(localized: "This app has no App Store version yet.") }
        let listed = resources.map { "\($0.attributes.versionString) (\($0.attributes.state ?? "no state"))" }.joined(separator: ", ")
        return String(localized: "None of its App Store versions is in a state AppLocalizer reads: \(listed).")
    }

    /// The app info being prepared with the next version, else the live one.
    static func preferredAppInfo(in appInfos: [AppStoreConnectResource<AppInfoAttributes>]) -> AppStoreConnectResource<AppInfoAttributes>? {
        let finished: Set = ["READY_FOR_DISTRIBUTION", "REPLACED_WITH_NEW_INFO", "ACCEPTED"]
        return appInfos.first { !finished.contains($0.attributes.currentState ?? "") }
            ?? appInfos.first { $0.attributes.currentState == "READY_FOR_DISTRIBUTION" }
            ?? appInfos.first
    }
}
