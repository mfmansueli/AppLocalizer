//
//  DebugSummaries.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The overview numbers for the sample apps, as the design shows them.
enum DebugSummaries {
    typealias AppIDs = DebugFixtures.AppID

    static func pricing(for appID: StoreApp.ID) -> PricingSummary {
        switch appID {
        case AppIDs.lumen:
            subscriptions(group: "Lumen Plus", productPrefix: "lumen.plus", monthly: "$4.99", annual: "$39.99", lifetime: "$79.99", custom: 3, heldBack: 146)
        case AppIDs.habitat:
            subscriptions(group: "Habitat Pro", productPrefix: "habitat.pro", monthly: "$2.99", annual: "$24.99", custom: 1, heldBack: 149)
        case AppIDs.tempo:
            subscriptions(group: "Tempo Pro", productPrefix: "tempo.pro", monthly: "$2.99", annual: "$19.99", custom: 0, heldBack: 148)
        case AppIDs.fieldnote:
            subscriptions(group: "Fieldnote Pro", productPrefix: "fieldnote.pro", monthly: "$3.99", annual: "$29.99", custom: 0, heldBack: 148)
        case AppIDs.parcel:
            subscriptions(group: "Parcel Pal Plus", productPrefix: "parcel.plus", monthly: "$1.99", annual: "$14.99", custom: 0, heldBack: 148)
        default:
            .empty
        }
    }

    static func storePage(for appID: StoreApp.ID) -> StorePageSummary {
        switch appID {
        case AppIDs.lumen:
            StorePageSummary(
                versionString: "1.4",
                versionState: "Prepare for Submission",
                hasEditableVersion: true,
                localeCount: 10,
                localeCodes: StorePageSampleData.presentLocales.map(\.code),
                completeness: 0.88,
                missingCount: 11,
                machineTranslatedCount: 1,
                overLimitCount: 1
            )
        case AppIDs.habitat: released(locales: 18, completeness: 0.91, missing: 9)
        case AppIDs.tempo: released(locales: 39, completeness: 0.94, missing: 21)
        case AppIDs.fieldnote: released(locales: 6, completeness: 0.94, missing: 3)
        case AppIDs.parcel: released(locales: 2, completeness: 1, missing: 0)
        default: released(locales: 12, completeness: 0.9, missing: 6)
        }
    }

    static func appInformation(for _: StoreApp.ID) -> AppInformationSummary {
        AppInformationSummary(ageRating: "4+", isAppReviewComplete: true)
    }

    private static func released(locales: Int, completeness: Double, missing: Int) -> StorePageSummary {
        StorePageSummary(
            versionString: "2.3",
            versionState: "Ready for Distribution",
            hasEditableVersion: false,
            localeCount: locales,
            completeness: completeness,
            missingCount: missing,
            machineTranslatedCount: 0,
            overLimitCount: 0
        )
    }

    private static func subscriptions(
        group: String,
        productPrefix: String,
        monthly: String,
        annual: String,
        lifetime: String? = nil,
        custom: Int,
        heldBack: Int
    ) -> PricingSummary {
        var products = [
            PricingSummary.Product(id: "\(productPrefix).monthly", name: "\(group) Monthly", productID: "\(productPrefix).monthly", duration: "1 month", basePrice: monthly, isInAppPurchase: false),
            PricingSummary.Product(id: "\(productPrefix).annual", name: "\(group) Annual", productID: "\(productPrefix).annual", duration: "1 year", basePrice: annual, isInAppPurchase: false),
        ]
        if let lifetime {
            let prefix = productPrefix.split(separator: ".").first.map(String.init) ?? productPrefix
            let name = group.split(separator: " ").first.map(String.init) ?? group
            products.append(PricingSummary.Product(
                id: "\(prefix).lifetime",
                name: "\(name) Lifetime",
                productID: "\(prefix).lifetime",
                duration: "Non-consumable",
                basePrice: lifetime,
                isInAppPurchase: true
            ))
        }
        return PricingSummary(
            groupCount: 1,
            subscriptionCount: 2,
            inAppPurchaseCount: lifetime == nil ? 0 : 1,
            products: products,
            reportedProductName: "Annual",
            equalizedTerritoryCount: 175 - custom,
            customTerritoryCount: custom,
            heldBackTerritoryCount: heldBack,
            baseTerritoryName: "US"
        )
    }
}
#endif
