//
//  AppInformationPage.swift
//  AppLocalizer
//

import Foundation

/// One page in App Information's page column, in the column's order.
enum AppInformationPage: String, CaseIterable, Identifiable, Hashable, Sendable {
    case general
    case ageRating
    case accessibility
    case appPrivacy
    case appReview
    case exportCompliance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .ageRating: String(localized: "Age Rating")
        case .accessibility: String(localized: "Accessibility")
        case .appPrivacy: String(localized: "App Privacy")
        case .appReview: String(localized: "App Review")
        case .exportCompliance: String(localized: "Export Compliance")
        }
    }
}
