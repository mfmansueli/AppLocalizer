//
//  DebugWorkspace.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The window-wide state DEBUG scenes start from: Habitat's three pending
/// store-page edits, Lumen's last push and Tempo set to Keep my prices.
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

    static var pushRecords: [PushRecord] {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = .current
        components.year = 2026
        components.month = 10
        components.day = 12
        components.hour = 14
        components.minute = 32
        return [
            PushRecord(
                date: components.date ?? .now,
                appID: AppIDs.lumen,
                appName: "Lumen Journal",
                title: String(localized: "Store Page · 24 texts in 8 locales"),
                pushed: []
            ),
        ]
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
