//
//  InAppTextsLoader.swift
//  AppLocalizer
//

import Foundation

/// Reads the In-App Texts: the first subscription group's name, each of its
/// subscriptions and every in-app purchase, with their localizations.
struct InAppTextsLoader: Sendable {
    let client: AppStoreConnectClient

    func content(for app: StoreApp) async throws -> InAppTextsContent {
        var content = InAppTextsContent.empty
        if let group = try await client.subscriptionGroups(appID: app.id).first {
            content.groupID = group.id
            for localization in try await client.subscriptionGroupLocalizations(groupID: group.id) {
                guard let locale = StoreLocaleCatalog.locale(code: localization.attributes.locale) else { continue }
                content.groupLocalizations[locale] = localization.id
                content.set(localization.attributes.name, column: InAppTextColumn.groupName.id, in: locale)
            }
            for subscription in try await client.subscriptions(groupID: group.id) {
                let product = InAppTextProduct(id: subscription.attributes.productId, referenceName: subscription.attributes.name, kind: .subscription)
                let localizations = try await client.subscriptionLocalizations(subscriptionID: subscription.id)
                content.add(product, resourceID: subscription.id, localizations: localizations.map {
                    .init(id: $0.id, locale: $0.attributes.locale, name: $0.attributes.name, description: $0.attributes.description)
                })
            }
        }
        for purchase in try await client.inAppPurchases(appID: app.id) {
            let product = InAppTextProduct(id: purchase.attributes.productId, referenceName: purchase.attributes.name, kind: .inAppPurchase)
            let localizations = try await client.inAppPurchaseLocalizations(purchaseID: purchase.id)
            content.add(product, resourceID: purchase.id, localizations: localizations.map {
                .init(id: $0.id, locale: $0.attributes.locale, name: $0.attributes.name, description: $0.attributes.description)
            })
        }
        return content
    }
}
