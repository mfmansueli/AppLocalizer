//
//  InAppTextsLoader.swift
//  AppLocalizer
//

import Foundation

/// Reads the In-App Texts: the first subscription group's name, each of its
/// subscriptions and every in-app purchase, with their localizations.
///
/// Since App Store Connect API 4.4.1 each one's texts live in numbered
/// versions, and the pre-4.4.1 localizations can't be written any more
/// (`ENTITY_ERROR.ATTRIBUTE.INVALID.UNMODIFIABLE`). So for each owner the
/// loader reads the version that takes edits and its localizations; with
/// none, the current texts, and the push makes a draft
/// (`InAppDraftWrite`). An owner App Store Connect has no versions for is
/// read and written the old way.
struct InAppTextsLoader: Sendable {
    let client: AppStoreConnectClient

    func content(for app: StoreApp) async throws -> InAppTextsContent {
        var content = InAppTextsContent.empty
        if let group = try await client.subscriptionGroups(appID: app.id).first {
            content.groupID = group.id
            let groupLocalizations = try await versioned(
                key: InAppTextsContent.groupKey,
                into: &content,
                versions: { try await client.subscriptionGroupVersions(groupID: group.id) },
                ofVersion: { try await client.subscriptionGroupVersionLocalizations(versionID: $0) },
                current: { try await client.subscriptionGroupLocalizations(groupID: group.id) }
            )
            for localization in groupLocalizations {
                guard let locale = StoreLocaleCatalog.locale(code: localization.attributes.locale) else { continue }
                content.groupLocalizations[locale] = localization.id
                content.set(localization.attributes.name, column: InAppTextColumn.groupName.id, in: locale)
            }
            for subscription in try await client.subscriptions(groupID: group.id) {
                let product = InAppTextProduct(id: subscription.attributes.productId, referenceName: subscription.attributes.name, kind: .subscription)
                let localizations = try await versioned(
                    key: product.id,
                    into: &content,
                    versions: { try await client.subscriptionVersions(subscriptionID: subscription.id) },
                    ofVersion: { try await client.subscriptionVersionLocalizations(versionID: $0) },
                    current: { try await client.subscriptionLocalizations(subscriptionID: subscription.id) }
                )
                content.add(product, resourceID: subscription.id, localizations: localizations.map {
                    .init(id: $0.id, locale: $0.attributes.locale, name: $0.attributes.name, description: $0.attributes.description)
                })
            }
        }
        for purchase in try await client.inAppPurchases(appID: app.id) {
            let product = InAppTextProduct(id: purchase.attributes.productId, referenceName: purchase.attributes.name, kind: .inAppPurchase)
            let localizations = try await versioned(
                key: product.id,
                into: &content,
                versions: { try await client.inAppPurchaseVersions(purchaseID: purchase.id) },
                ofVersion: { try await client.inAppPurchaseVersionLocalizations(versionID: $0) },
                current: { try await client.inAppPurchaseLocalizations(purchaseID: purchase.id) }
            )
            content.add(product, resourceID: purchase.id, localizations: localizations.map {
                .init(id: $0.id, locale: $0.attributes.locale, name: $0.attributes.name, description: $0.attributes.description)
            })
        }
        return content
    }

    /// One owner's localizations: its editable version's (noted in
    /// `editableVersions`), else the current ones. A versions list App
    /// Store Connect can't find marks the owner legacy.
    private func versioned<Localization>(
        key: String,
        into content: inout InAppTextsContent,
        versions: () async throws -> [AppStoreConnectResource<InAppTextVersionAttributes>],
        ofVersion: (String) async throws -> [Localization],
        current: () async throws -> [Localization]
    ) async throws -> [Localization] {
        let list: [AppStoreConnectResource<InAppTextVersionAttributes>]
        do {
            list = try await versions()
        } catch AppStoreConnectError.notFound {
            content.legacyOwners.insert(key)
            return try await current()
        }
        if let latest = list.max(by: { ($0.attributes.version ?? 0) < ($1.attributes.version ?? 0) }) {
            content.latestVersions[key] = latest.attributes
        }
        guard let editable = Self.editableVersion(in: list) else { return try await current() }
        content.editableVersions[key] = editable.id
        return try await ofVersion(editable.id)
    }

    /// The newest version that takes edits.
    static func editableVersion(in versions: [AppStoreConnectResource<InAppTextVersionAttributes>]) -> AppStoreConnectResource<InAppTextVersionAttributes>? {
        versions
            .filter { InAppTextsContent.editableVersionStates.contains($0.attributes.state ?? "") }
            .max { ($0.attributes.version ?? 0) < ($1.attributes.version ?? 0) }
    }
}
