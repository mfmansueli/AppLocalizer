//
//  StorePageContentFixtures.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// `StorePageFixtures`' listing as App Store Connect content: version 2.0
/// (editable) and 1.9 (live), with resource IDs for both locales.
enum StorePageContentFixtures {
    static let app = StoreApp(id: "app1", name: "Lumen Journal", bundleID: "dev.example.lumen", sku: "LUMEN", primaryLocale: "en-US")

    static let editableVersion = StorePageVersion(id: "v2", listingVersion: StorePageFixtures.editableVersion, platform: "IOS")
    static let liveVersion = StorePageVersion(id: "v19", listingVersion: StorePageFixtures.liveVersion, platform: "IOS")

    static let ids = ListingResourceIDs(
        versionID: "v2",
        appInfoID: "info",
        versionLocalizations: [.englishUS: "vl-en", .german: "vl-de"],
        appInfoLocalizations: [.englishUS: "il-en", .german: "il-de"]
    )

    static var editable: StorePageContent { content(version: editableVersion, ids: ids) }

    static var live: StorePageContent {
        var ids = ids
        ids.versionID = "v19"
        ids.versionLocalizations = [.englishUS: "vl19-en", .german: "vl19-de"]
        return content(version: liveVersion, ids: ids)
    }

    /// Only the live version: "No version to edit".
    static var liveOnly: StorePageContent {
        var content = live
        content.versions = [liveVersion]
        return content
    }

    static func content(version: StorePageVersion, ids: ListingResourceIDs) -> StorePageContent {
        StorePageContent(
            appName: "Lumen Journal",
            primaryLocale: .englishUS,
            versions: [editableVersion, liveVersion],
            version: version,
            locales: [.englishUS, .german],
            texts: [.englishUS: StorePageFixtures.englishTexts, .german: StorePageFixtures.germanTexts],
            ids: ids
        )
    }

    static func changeID(_ locale: StoreLocale, _ field: ListingField, versionID: String = "v2") -> String {
        switch field.level {
        case .app: "storePage.app1.appInfo.info.\(locale.code).\(field.rawValue)"
        case .version: "storePage.app1.version.\(versionID).\(locale.code).\(field.rawValue)"
        }
    }
}
