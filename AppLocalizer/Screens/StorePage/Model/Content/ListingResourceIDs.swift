//
//  ListingResourceIDs.swift
//  AppLocalizer
//

import Foundation

/// App Store Connect's resource IDs behind one listing: where each field's
/// `PATCH` goes, and the parent a new locale is `POST`ed under.
struct ListingResourceIDs: Hashable, Sendable {
    /// The `appStoreVersions` resource whose texts are shown.
    var versionID: String
    /// The `appInfos` resource for name, subtitle and privacy policy URL:
    /// the one being prepared with the next version, else the live one.
    var appInfoID: String
    var versionLocalizations: [StoreLocale: String] = [:]
    var appInfoLocalizations: [StoreLocale: String] = [:]

    /// The localization resource a field of `locale` lives on, or nil when
    /// the locale doesn't exist in App Store Connect at that level yet.
    func localizationID(for locale: StoreLocale, at level: ListingFieldLevel) -> String? {
        switch level {
        case .app: appInfoLocalizations[locale]
        case .version: versionLocalizations[locale]
        }
    }

    /// The parent resource of every localization at `level`.
    func parentID(at level: ListingFieldLevel) -> String {
        switch level {
        case .app: appInfoID
        case .version: versionID
        }
    }
}
