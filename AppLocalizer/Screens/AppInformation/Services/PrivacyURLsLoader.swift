//
//  PrivacyURLsLoader.swift
//  AppLocalizer
//

import Foundation

/// Reads the privacy URLs of every locale from App Store Connect: the app
/// info Store Page edits (the one being prepared, else the live one), and
/// its localizations' `privacyPolicyUrl` and `privacyChoicesUrl`.
struct PrivacyURLsLoader: Sendable {
    let client: AppStoreConnectClient

    /// The two attributes this tab needs from `appInfoLocalizations`.
    private struct Attributes: Decodable, Sendable {
        var locale: String
        var privacyPolicyUrl: String?
        var privacyChoicesUrl: String?
    }

    func content(for app: StoreApp) async throws -> PrivacyURLsContent {
        let appInfos = try await client.appInfos(appID: app.id)
        guard let appInfo = StorePageContentLoader.preferredAppInfo(in: appInfos) else {
            throw AppStoreConnectError.notFound(detail: String(localized: "This app has no app information yet."))
        }
        let query = [
            URLQueryItem(name: "fields[appInfoLocalizations]", value: "locale,privacyPolicyUrl,privacyChoicesUrl"),
            URLQueryItem(name: "limit", value: "200"),
        ]
        let resources: [AppStoreConnectResource<Attributes>] = try await client.allPages(
            of: "/v1/appInfos/\(appInfo.id)/appInfoLocalizations",
            query: query
        )
        let locales = resources.compactMap { resource -> PrivacyURLsLocale? in
            guard let locale = StoreLocaleCatalog.locale(code: resource.attributes.locale) else { return nil }
            return PrivacyURLsLocale(
                locale: locale,
                localizationID: resource.id,
                policyURL: resource.attributes.privacyPolicyUrl ?? "",
                choicesURL: resource.attributes.privacyChoicesUrl ?? ""
            )
        }
        let primary = app.primaryLocale.flatMap(StoreLocaleCatalog.resolve)?.locale ?? .englishUS
        return PrivacyURLsContent(appInfoID: appInfo.id, primaryLocale: primary, locales: locales)
    }
}
