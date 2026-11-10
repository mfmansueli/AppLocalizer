//
//  OverviewWaitingSection.swift
//  AppLocalizer
//

import Foundation

/// A row of the Overview's "suggestions waiting for you": a section, what
/// it changes on the App Store, where its suggestions are, and how many.
struct OverviewWaitingSection: Identifiable, Hashable, Sendable {
    var section: AppWorkspaceSection
    var count: Int
    /// "Text in 6 languages, including 2 new pages", "Every caption reviewed".
    var detail: String

    var id: AppWorkspaceSection { section }

    var title: String { section.title }

    /// What the section changes: "The words on the page and in search".
    func what(appName: String) -> String {
        switch section {
        case .overview: ""
        case .storePage: String(localized: "The words on the page and in search")
        case .screenshots: String(localized: "The images people swipe through")
        case .subscriptionPricing: String(localized: "What \(appName) costs in each country")
        case .appInformation: String(localized: "Category, age rating, accessibility, App Review")
        }
    }

    var systemImage: String { Self.icon(for: section) }

    /// "Review" with something to review, else "Open".
    var buttonTitle: String {
        count > 0 ? String(localized: "Review") : String(localized: "Open")
    }

    /// "Open Store Page, 32 suggestions to review".
    var accessibilityText: String {
        switch count {
        case 0: String(localized: "Open \(title)")
        case 1: String(localized: "Open \(title), 1 suggestion to review")
        default: String(localized: "Open \(title), \(count) suggestions to review")
        }
    }

    static func icon(for section: AppWorkspaceSection) -> String {
        switch section {
        case .overview: "square.grid.2x2"
        case .storePage: "doc.text"
        case .screenshots: "iphone"
        case .subscriptionPricing: "tag"
        case .appInformation: "info.circle"
        }
    }

    // MARK: - Rows

    /// What each section's suggestions are about, from what's open.
    struct Facts: Equatable {
        var counts: SectionBadgeCounts
        /// Languages with Store Page suggestions, and how many of them have
        /// no App Store page yet.
        var storePageLanguages = 0
        var newPages = 0
        /// Languages with a caption suggested.
        var captionLanguages = 0
        /// Pricing's count is a guess until Pricing has read every product.
        var isPricingEstimate = false
        /// "Age Rating, Accessibility", in the page column's order.
        var informationPages: [String] = []
    }

    /// Store Page, Screenshots, Pricing and App Information, in the design's
    /// order.
    static func rows(_ facts: Facts) -> [OverviewWaitingSection] {
        [
            row(.storePage, facts, detail: storePageDetail(facts)),
            row(.screenshots, facts, detail: facts.captionLanguages == 1
                ? String(localized: "Captions in 1 language")
                : String(localized: "Captions in \(facts.captionLanguages) languages"), done: String(localized: "Every caption reviewed")),
            row(.subscriptionPricing, facts, detail: pricingDetail(facts), done: String(localized: "Every price reviewed")),
            row(.appInformation, facts, detail: facts.informationPages.joined(separator: ", "), done: String(localized: "Every page reviewed")),
        ]
    }

    private static func row(_ section: AppWorkspaceSection, _ facts: Facts, detail: String, done: String = "") -> OverviewWaitingSection {
        let count = facts.counts.count(for: section)
        let fallback = done.isEmpty ? String(localized: "Every language reviewed") : done
        return OverviewWaitingSection(section: section, count: count, detail: count > 0 ? detail : fallback)
    }

    private static func storePageDetail(_ facts: Facts) -> String {
        let languages = facts.storePageLanguages == 1
            ? String(localized: "Text in 1 language")
            : String(localized: "Text in \(facts.storePageLanguages) languages")
        switch facts.newPages {
        case 0: return languages
        case 1: return String(localized: "\(languages), including 1 new page")
        default: return String(localized: "\(languages), including \(facts.newPages) new pages")
        }
    }

    private static func pricingDetail(_ facts: Facts) -> String {
        guard !facts.isPricingEstimate else { return String(localized: "Prices that likely hold people back") }
        let count = facts.counts.count(for: .subscriptionPricing)
        return count == 1 ? String(localized: "Prices for 1 product") : String(localized: "Prices for \(count) products")
    }
}
