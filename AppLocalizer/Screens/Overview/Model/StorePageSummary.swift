//
//  StorePageSummary.swift
//  AppLocalizer
//

import Foundation

/// What the overview's Store page card, its header line and the sidebar's
/// coverage ring show for one app. Produced by `StorePageServices`.
struct StorePageSummary: Hashable, Sendable {
    /// The version the Store Page edits, e.g. "1.4"; nil when the app has none.
    var versionString: String?
    /// App Store Connect's state for it, e.g. "Prepare for Submission".
    var versionState: String?
    /// Whether that version can still be edited (not live or in review).
    var hasEditableVersion: Bool
    /// Locales with a store page.
    var localeCount: Int
    /// Every App Store locale.
    var totalLocaleCount: Int = 39
    /// Filled fields ÷ all fields across the app's locales, 0…1.
    var completeness: Double
    var missingCount: Int
    var machineTranslatedCount: Int
    var overLimitCount: Int
}
