//
//  WorkspaceServices.swift
//  AppLocalizer
//

import Foundation

/// Every feature's services for one connected account, handed from
/// `MainView` down to the sections. `live(client:)` talks to App Store
/// Connect; DEBUG scenes and previews build one from fakes.
@MainActor
struct WorkspaceServices {
    var appList: any AppListServices
    var pricing: any PricingServices
    var storePage: any StorePageServices
    var appInformation: any AppInformationServices
    /// Where Review & Push sends writes.
    var push: any PushTransport

    /// Screenshots; they come with the store page's services.
    var screenshots: any ScreenshotsServices { storePage.screenshots }

    static func live(client: AppStoreConnectClient) -> WorkspaceServices {
        WorkspaceServices(
            appList: LiveAppListServices(client: client),
            pricing: LivePricingServices(client: client),
            storePage: LiveStorePageServices(client: client),
            appInformation: LiveAppInformationServices(client: client),
            push: client
        )
    }
}
