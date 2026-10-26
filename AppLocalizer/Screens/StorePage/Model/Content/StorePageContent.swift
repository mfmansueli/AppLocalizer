//
//  StorePageContent.swift
//  AppLocalizer
//

import Foundation

/// One app's store page as App Store Connect has it: the versions to pick
/// from, the chosen version's texts and the IDs to write them back. Nothing
/// local is in here; pending changes and machine-translation tags are laid
/// on top by `StorePageViewModel`.
struct StorePageContent: Hashable, Sendable {
    var appName: String
    var primaryLocale: StoreLocale
    /// The picker's versions, newest first.
    var versions: [StorePageVersion]
    /// The version whose texts these are.
    var version: StorePageVersion
    /// Locales in the order App Store Connect returned them.
    var locales: [StoreLocale]
    /// App Store Connect's values per locale; empty fields are left out.
    var texts: [StoreLocale: [ListingField: String]]
    var ids: ListingResourceIDs

    /// The newest editable version, if there is one: when it's not the one
    /// shown, the picker can switch to it.
    var editableVersion: StorePageVersion? { versions.first(where: \.isEditable) }

    /// The editing model with App Store Connect's values. A field counts as
    /// machine-translated while its text is still the one that was accepted
    /// (`machineTranslated` maps `ListingFieldKey.id` to that text).
    func listing(machineTranslated: [String: String] = [:], addedLocales: [StoreLocale] = []) -> StoreListing {
        var listings = locales.map { locale in
            let remote = texts[locale] ?? [:]
            let tagged = remote.filter { field, value in machineTranslated[ListingFieldKey(locale, field).id] == value }
            return LocaleListing(locale: locale, remote: remote, machineTranslated: Set(tagged.keys))
        }
        for locale in addedLocales where !locales.contains(locale) {
            listings.append(LocaleListing(locale: locale))
        }
        return StoreListing(appName: appName, version: version.listingVersion, primaryLocale: primaryLocale, locales: listings)
    }
}
