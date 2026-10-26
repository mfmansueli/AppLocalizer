//
//  DebugStorePageContent.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `StorePageSampleData` dressed as App Store Connect would return it: the
/// Lumen Journal versions with made-up resource IDs, the in-app texts, and
/// the queued changes a scene starts with.
enum DebugStorePageContent {
    static let editableVersionID = "lumen-version-1.4"
    static let liveVersionID = "lumen-version-1.3"
    static let appInfoID = "lumen-appinfo"

    static let editableVersion = StorePageVersion(id: editableVersionID, listingVersion: StorePageSampleData.editableVersion, platform: "IOS")
    static let liveVersion = StorePageVersion(id: liveVersionID, listingVersion: StorePageSampleData.liveVersion, platform: "IOS")

    /// Lumen Journal's store page for `versionID` (the editable 1.4 by
    /// default), or only the live 1.3 when `hasEditableVersion` is false.
    static func lumen(versionID: String?, hasEditableVersion: Bool = true) -> StorePageContent {
        let versions = hasEditableVersion ? [editableVersion, liveVersion] : [liveVersion]
        let version = versions.first { $0.id == versionID } ?? versions[0]
        let listing = version.isEditable ? StorePageSampleData.fetchedListing : StorePageSampleData.liveListing
        return content(appName: StorePageSampleData.appName, versions: versions, version: version, listing: listing)
    }

    /// Any other sample app: its released version only, with Lumen's texts.
    static func released(appName: String, versionString: String) -> StorePageContent {
        let version = StorePageVersion(
            id: "version-\(versionString)",
            listingVersion: ListingVersion(versionString, state: .readyForDistribution),
            platform: "IOS"
        )
        return content(appName: appName, versions: [version], version: version, listing: StorePageSampleData.liveListing)
    }

    /// The pending changes `listing`'s edits make, as if queued earlier.
    static func pendingChanges(for listing: StoreListing, appID: StoreApp.ID = DebugFixtures.AppID.lumen) -> [PendingChange] {
        let content = lumen(versionID: editableVersionID)
        return ListingChangeBuilder(appID: appID, ids: content.ids, versionString: content.version.versionString).changes(for: listing)
    }

    /// The Japanese keywords were accepted machine translation and pushed
    /// without review, so this Mac still tags them.
    static var machineTranslationTags: [String: [String: String]] {
        let key = ListingFieldKey(.japanese, .keywords)
        let text = StorePageSampleData.remoteTexts[.japanese]?[.keywords] ?? ""
        let scope = MachineTranslationScope.version(editableVersionID)
        return [InMemoryMachineTranslationStore.key(DebugFixtures.AppID.lumen, scope): [key.id: text]]
    }

    /// The subscription group, two subscriptions and a lifetime purchase.
    static var inAppTexts: InAppTextsContent {
        let texts = StorePageSampleData.inAppRemoteTexts
        var groupLocalizations: [StoreLocale: String] = [:]
        var productLocalizations: [String: [StoreLocale: String]] = [:]
        for (locale, columns) in texts {
            if columns["group.name"] != nil { groupLocalizations[locale] = "group-\(locale.code)" }
            for product in StorePageSampleData.products where columns.keys.contains(where: { $0.hasPrefix(product.id + ".") }) {
                productLocalizations[product.id, default: [:]][locale] = "\(product.id)-\(locale.code)"
            }
        }
        return InAppTextsContent(
            products: StorePageSampleData.products,
            texts: texts,
            groupID: "lumen-plus-group",
            groupLocalizations: groupLocalizations,
            productResourceIDs: Dictionary(uniqueKeysWithValues: StorePageSampleData.products.map { ($0.id, "resource-\($0.id)") }),
            productLocalizations: productLocalizations
        )
    }

    private static func content(appName: String, versions: [StorePageVersion], version: StorePageVersion, listing: StoreListing) -> StorePageContent {
        var ids = ListingResourceIDs(versionID: version.id, appInfoID: appInfoID)
        var texts: [StoreLocale: [ListingField: String]] = [:]
        for locale in listing.locales {
            ids.versionLocalizations[locale] = "\(version.id)-\(locale.code)"
            ids.appInfoLocalizations[locale] = "\(appInfoID)-\(locale.code)"
            texts[locale] = listing.localeListing(locale).map { localeListing in
                Dictionary(uniqueKeysWithValues: ListingField.allCases.compactMap { field in
                    let value = localeListing.value(field)
                    return value.isEmpty ? nil : (field, value)
                })
            }
        }
        return StorePageContent(
            appName: appName,
            primaryLocale: listing.primaryLocale,
            versions: versions,
            version: version,
            locales: listing.locales,
            texts: texts,
            ids: ids
        )
    }
}
#endif
