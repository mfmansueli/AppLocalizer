//
//  FirstSyncProgress.swift
//  AppLocalizer
//

import Foundation

/// How far the first sync after connecting a key has come: the app list,
/// then each app's subscriptions, store page and App Information, one app
/// at a time.
struct FirstSyncProgress: Equatable, Sendable {
    /// nil while the app list itself is loading.
    var appCount: Int?
    /// Apps whose summaries have loaded.
    var syncedCount = 0

    /// 0…1 for the progress bar; the app list counts as the first step.
    var fraction: Double {
        guard let appCount else { return 0 }
        guard appCount > 0 else { return 1 }
        return (1 + Double(min(syncedCount, appCount))) / (1 + Double(appCount))
    }

    /// "Found 6 apps · reading subscriptions and store pages (3 of 6)".
    var detail: String {
        guard let appCount else { return String(localized: "Reading your team and apps…") }
        let found = appCount == 1 ? String(localized: "Found 1 app") : String(localized: "Found \(appCount) apps")
        let current = min(syncedCount + 1, appCount)
        return String(localized: "\(found) · reading subscriptions and store pages (\(current) of \(appCount))")
    }
}
