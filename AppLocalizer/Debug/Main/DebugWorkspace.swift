//
//  DebugWorkspace.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The window-wide state DEBUG scenes start from: Habitat's three pending
/// store-page edits, the push history and Tempo set to Keep my prices.
enum DebugWorkspace {
    typealias AppIDs = DebugFixtures.AppID

    static let pricingModes: [StoreApp.ID: PricingMode] = [
        AppIDs.lumen: .showSuggestions,
        AppIDs.habitat: .showSuggestions,
        AppIDs.tempo: .keepPrices,
    ]

    static var pendingChanges: [PendingChange] {
        [
            listingChange(locale: "German", region: "DE", field: "Subtitle", old: "Pflanzen gießen leicht gemacht", new: "Gießen, düngen, umtopfen"),
            listingChange(locale: "French", region: "FR", field: "Promotional Text", old: "", new: "Nouveau : rappels d’arrosage selon la météo."),
            listingChange(locale: "Japanese", region: "JP", field: "Keywords", old: "植物,水やり", new: "植物,水やり,観葉植物,ガーデニング"),
        ]
    }

    /// Lumen's store-page push on Oct 12, Habitat's prices with two
    /// failures and Lumen's earlier price push.
    static var pushRecords: [PushRecord] {
        DebugReviewData.activityRecords
    }

    private static func listingChange(locale: String, region: String, field: String, old: String, new: String) -> PendingChange {
        PendingChange(
            id: "listing.debug-habitat.\(region).\(field)",
            appID: AppIDs.habitat,
            section: .storePage,
            group: String(localized: "Store Page · Version 3.1"),
            title: "\(locale) · \(field)",
            flagRegion: region,
            oldValue: old,
            newValue: new,
            requests: []
        )
    }
}
#endif
