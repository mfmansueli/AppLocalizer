//
//  ProComparisonRow.swift
//  AppLocalizer
//

import Foundation

/// One row of Compare Free and Pro: the full split, a feature at a time.
struct ProComparisonRow: Hashable, Sendable, Identifiable {
    var feature: String
    var free: String
    var pro: String

    var id: String { feature }

    /// Free doesn't have it at all.
    var isMissingInFree: Bool { free == Self.none }

    static let none = "—"
    static let yes = "✓"

    static var all: [ProComparisonRow] {
        [
            ProComparisonRow(
                feature: String(localized: "Apps and App Store Connect accounts"),
                free: String(localized: "1 app, 1 account"), pro: String(localized: "Unlimited")
            ),
            ProComparisonRow(
                feature: String(localized: "Store Page, App Information, Pricing in every language"),
                free: String(localized: "Edit and push"), pro: String(localized: "Edit and push")
            ),
            ProComparisonRow(feature: String(localized: "Built-in checks and suggestions"), free: yes, pro: yes),
            ProComparisonRow(
                feature: String(localized: "Suggestions from your AI assistant"),
                free: String(localized: "One at a time"), pro: String(localized: "One at a time or all at once")
            ),
            ProComparisonRow(feature: String(localized: "Accept All Languages, Translate All"), free: none, pro: yes),
            ProComparisonRow(feature: String(localized: "Review & Push"), free: yes, pro: yes),
            ProComparisonRow(
                feature: String(localized: "Screenshot editor"),
                free: String(localized: "3 templates · iPhone and iPad"), pro: String(localized: "14 templates · every device")
            ),
            ProComparisonRow(feature: String(localized: "Autopilot"), free: none, pro: yes),
            ProComparisonRow(feature: String(localized: "Recommended prices for 175 countries"), free: none, pro: yes),
            ProComparisonRow(feature: String(localized: "Retention messages and offers"), free: none, pro: yes),
        ]
    }
}
