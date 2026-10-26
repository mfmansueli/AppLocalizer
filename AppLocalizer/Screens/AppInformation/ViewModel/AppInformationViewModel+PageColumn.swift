//
//  AppInformationViewModel+PageColumn.swift
//  AppLocalizer
//

import Foundation

// The page column: each page's one-line status and its unpushed dot.
extension AppInformationViewModel {
    /// e.g. "Lifestyle · Health & Fitness", "9+", "1 published · 1 not
    /// declared", "In progress", "Complete", "Exempt"; nil while loading.
    /// App Privacy's comes from the worksheet on this Mac.
    func status(for page: AppInformationPage) -> String? {
        switch page {
        case .general: general.map { $0.categorySummary.isEmpty ? String(localized: "No category") : $0.categorySummary }
        case .ageRating: ratingPreview?.effective.title
        case .accessibility: accessibilityStatus
        case .appPrivacy: privacy.status.title
        case .appReview: review.map { $0.isComplete ? String(localized: "Complete") : String(localized: "Missing details") }
        case .exportCompliance: exportAnswers?.status
        }
    }

    /// Whether the page has changes waiting in Review & Push.
    /// App Privacy counts the Privacy Policy URLs it edits, which are
    /// Store Page's changes.
    func hasPendingChanges(on page: AppInformationPage) -> Bool {
        let builder = builder
        if changes.contains(where: { builder.page(of: $0) == page }) { return true }
        guard page == .appPrivacy else { return false }
        let prefix = "storePage.\(app.id).appInfo."
        let suffix = ".\(ListingField.privacyPolicyURL.rawValue)"
        return queue.changes(for: app.id, section: .storePage).contains { $0.id.hasPrefix(prefix) && $0.id.hasSuffix(suffix) }
    }

    private var accessibilityStatus: String? {
        switch accessibility {
        case .idle, .loading: return nil
        case .failed: return String(localized: "Couldn’t load")
        case .loaded:
            let cards = accessibilityCards
            let published = cards.count(where: \.isPublished)
            let notDeclared = cards.count { $0.state == .notDeclared }
            return String(localized: "\(published) published · \(notDeclared) not declared")
        }
    }
}
