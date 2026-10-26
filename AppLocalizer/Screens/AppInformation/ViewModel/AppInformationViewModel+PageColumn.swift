//
//  AppInformationViewModel+PageColumn.swift
//  AppLocalizer
//

import Foundation

// The page column: each page's one-line status and its unpushed dot.
extension AppInformationViewModel {
    /// e.g. "Lifestyle · Health & Fitness", "9+", "1 published · 1 not
    /// declared", "Complete", "Exempt"; nil while loading, and for App
    /// Privacy, which comes later.
    func status(for page: AppInformationPage) -> String? {
        switch page {
        case .general: general.map { $0.categorySummary.isEmpty ? String(localized: "No category") : $0.categorySummary }
        case .ageRating: ratingPreview?.effective.title
        case .accessibility: accessibilityStatus
        case .appPrivacy: nil
        case .appReview: review.map { $0.isComplete ? String(localized: "Complete") : String(localized: "Missing details") }
        case .exportCompliance: exportAnswers?.status
        }
    }

    /// Whether the page has changes waiting in Review & Push.
    func hasPendingChanges(on page: AppInformationPage) -> Bool {
        let builder = builder
        return changes.contains { builder.page(of: $0) == page }
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
