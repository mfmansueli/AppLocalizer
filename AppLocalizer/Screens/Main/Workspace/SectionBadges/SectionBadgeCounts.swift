//
//  SectionBadgeCounts.swift
//  AppLocalizer
//

import Foundation

/// How many suggestions wait in each workspace section, for the badges on
/// the toolbar's section picker. Sections without suggestions have no badge.
struct SectionBadgeCounts: Equatable {
    /// More than this reads "99+", so the toolbar keeps its width.
    static let maximumShown = 99

    private let counts: [AppWorkspaceSection: Int]

    init(_ counts: [AppWorkspaceSection: Int] = [:]) {
        self.counts = counts
    }

    /// The open field suggestions, captions an assistant suggested and, from
    /// Pricing, products with an open price suggestion.
    @MainActor
    init(appID: StoreApp.ID, suggestions: FieldSuggestionStore, screenshots: ScreenshotsDocumentCenter? = nil, pricing: Int = 0) {
        var counts: [AppWorkspaceSection: Int] = [:]
        for area in SuggestionArea.allCases {
            counts[area.section, default: 0] += suggestions.toReview(for: appID, area: area).count
        }
        counts[.screenshots, default: 0] += screenshots?.openCaptionCount(appID: appID) ?? 0
        counts[.subscriptionPricing, default: 0] += pricing
        self.counts = counts
    }

    /// Products with an open price suggestion: Pricing's count once it has
    /// read every product this launch; before that, 1 when the product the
    /// summary describes has prices likely holding people back and nothing
    /// for it is queued or dismissed. Apps set to Keep my prices have none.
    @MainActor
    static func pricingCount(appID: StoreApp.ID, summaries: AppSummaryStore, modes: PricingModeStore, changes: ChangeQueue) -> Int {
        guard modes.mode(for: appID).showsSuggestions else { return 0 }
        if let exact = summaries.pricingSuggestionCounts[appID] { return exact }
        guard let summary = summaries.pricing[appID]?.value, summary.sellsAnything, (summary.heldBackTerritoryCount ?? 0) > 0,
              modes.dismissedPriceSuggestions[appID]?.isEmpty ?? true,
              changes.changes(for: appID, section: .subscriptionPricing).isEmpty
        else { return 0 }
        return 1
    }

    /// Every section's count together, for the app in the sidebar.
    var total: Int {
        counts.values.reduce(0, +)
    }

    func count(for section: AppWorkspaceSection) -> Int {
        counts[section] ?? 0
    }

    /// "12", "99+", or nil when the section has none.
    func text(for section: AppWorkspaceSection) -> String? {
        let count = count(for: section)
        guard count > 0 else { return nil }
        return count > Self.maximumShown ? "\(Self.maximumShown)+" : "\(count)"
    }

    /// Every section's exact count, for VoiceOver: "Store Page, 12
    /// suggestions to review. App Information, 1 suggestion to review."
    var accessibilitySummary: String {
        let parts = AppWorkspaceSection.allCases.filter { count(for: $0) > 0 }.map { section in
            let count = count(for: section)
            return count == 1
                ? String(localized: "\(section.title), 1 suggestion to review")
                : String(localized: "\(section.title), \(count) suggestions to review")
        }
        return parts.isEmpty ? String(localized: "No suggestions to review") : parts.joined(separator: ". ")
    }
}
