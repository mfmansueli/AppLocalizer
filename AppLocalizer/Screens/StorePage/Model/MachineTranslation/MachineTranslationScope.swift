//
//  MachineTranslationScope.swift
//  AppLocalizer
//

import Foundation

/// The scope keys `MachineTranslationStore` files tags under: version-level
/// texts per version, app-level texts per app info.
enum MachineTranslationScope {
    static func version(_ versionID: String) -> String {
        "version.\(versionID)"
    }

    static func appInfo(_ appInfoID: String) -> String {
        "appInfo.\(appInfoID)"
    }

    /// The scope a field of `ids`' listing is tagged under.
    static func scope(for level: ListingFieldLevel, ids: ListingResourceIDs) -> String {
        switch level {
        case .app: appInfo(ids.appInfoID)
        case .version: version(ids.versionID)
        }
    }

    /// Both scopes' tags for one listing, merged (keys never overlap).
    @MainActor
    static func tags(in store: any MachineTranslationStore, appID: StoreApp.ID, ids: ListingResourceIDs) -> [String: String] {
        store.tags(appID: appID, scope: appInfo(ids.appInfoID))
            .merging(store.tags(appID: appID, scope: version(ids.versionID))) { first, _ in first }
    }
}
