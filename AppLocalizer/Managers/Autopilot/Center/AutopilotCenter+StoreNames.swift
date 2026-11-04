//
//  AutopilotCenter+StoreNames.swift
//  AppLocalizer
//

import Foundation

/// Each language's App Store name on the app's run, so everything the run
/// renders, from the Studio or from an assistant's tools, writes the name
/// that language's page has.
extension AutopilotCenter {
    /// Keeps `names` (locale → name) on the app's run whenever AppLocalizer
    /// reads its page (the Studio's store texts, the design brief), over
    /// the ones it had; nothing without a run, or when nothing changes.
    func noteStoreNames(_ names: [String: String], appID: StoreApp.ID) {
        guard let run = runs[appID] else { return }
        let kept = (run.storeNames ?? [:]).merging(AutopilotRun.storeNames(names)) { $1 }
        guard !kept.isEmpty, kept != run.storeNames else { return }
        update(appID) { $0.storeNames = kept }
    }
}
