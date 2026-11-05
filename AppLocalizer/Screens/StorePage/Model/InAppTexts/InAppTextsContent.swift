//
//  InAppTextsContent.swift
//  AppLocalizer
//

import Foundation

/// The In-App Texts view's data as App Store Connect has it: the
/// subscription group and products, every localized name and description,
/// and the IDs to write them back.
struct InAppTextsContent: Hashable, Sendable {
    var products: [InAppTextProduct]
    /// App Store Connect's values: locale → column ID → text.
    var texts: [StoreLocale: [String: String]]
    /// The `subscriptionGroups` resource the group name belongs to; nil when
    /// the app has no subscriptions.
    var groupID: String?
    /// Group name localizations: locale → `subscriptionGroupLocalizations` ID.
    var groupLocalizations: [StoreLocale: String] = [:]
    /// Product ID → `subscriptions` or `inAppPurchases` resource ID.
    var productResourceIDs: [String: String] = [:]
    /// Product ID → locale → localization resource ID.
    var productLocalizations: [String: [StoreLocale: String]] = [:]
    /// Owner (`groupKey` or a product ID) → the version that takes edits,
    /// whose localizations the IDs above are. An owner without one has its
    /// current texts here, and a push finds or creates a draft for them.
    var editableVersions: [String: String] = [:]
    /// Owners App Store Connect has no versions for: written the pre-4.4.1
    /// way.
    var legacyOwners: Set<String> = []
    /// Owner → its newest version, whatever its state, so
    /// `get_in_app_texts` can say where texts go (e.g. one in a review
    /// submission).
    var latestVersions: [String: InAppTextVersionAttributes] = [:]

    /// The owner key of the subscription group.
    static let groupKey = "group"

    /// The version states that take edits: not submitted yet (a draft
    /// review submission still counts), or rejected.
    static let editableVersionStates: Set<String> = ["PREPARE_FOR_SUBMISSION", "READY_FOR_REVIEW", "REJECTED", "DEVELOPER_REJECTED"]

    static let empty = InAppTextsContent(products: [], texts: [:])

    /// Nothing to localize: no subscription group and no products.
    var isEmpty: Bool { products.isEmpty && groupID == nil }

    /// Locales that have at least one in-app text.
    var locales: [StoreLocale] {
        texts.keys.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The matrix with App Store Connect's values, listing `locales` (the
    /// store page's) plus any locale only the in-app texts have.
    func matrix(primaryLocale: StoreLocale, locales listingLocales: [StoreLocale]) -> InAppTextMatrix {
        let extra = locales.filter { !listingLocales.contains($0) }
        return InAppTextMatrix(products: products, primaryLocale: primaryLocale, locales: listingLocales + extra, remote: texts)
    }

    /// The localization ID of the group name (`productID` nil) or a
    /// product's texts in `locale`, if App Store Connect has one.
    func localizationID(productID: String?, locale: StoreLocale) -> String? {
        guard let productID else { return groupLocalizations[locale] }
        return productLocalizations[productID]?[locale]
    }
}
