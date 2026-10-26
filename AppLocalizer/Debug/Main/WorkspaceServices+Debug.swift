//
//  WorkspaceServices+Debug.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

extension WorkspaceServices {
    /// The sample account's canned data for every section; replace single
    /// services to reach a state (`var services = .debug; services.pricing = …`).
    static var debug: WorkspaceServices {
        WorkspaceServices(
            appList: DebugAppListServices(),
            pricing: DebugPricingServices(),
            storePage: DebugStorePageServices(),
            appInformation: DebugAppInformationServices()
        )
    }
}
#endif
