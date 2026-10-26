//
//  PrivacyDataCategory.swift
//  AppLocalizer
//

import Foundation

/// One of the 16 categories of App Store Connect's App Privacy
/// questionnaire, with Apple's exact names, in the order App Store Connect
/// lists them. The raw value is the id assistants use
/// (`get_privacy_questionnaire`).
enum PrivacyDataCategory: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    case contactInfo = "contact"
    case healthAndFitness = "health"
    case financialInfo = "financial"
    case location
    case sensitiveInfo = "sensitive"
    case contacts
    case userContent = "content"
    case browsingHistory = "browsing"
    case searchHistory = "search"
    case identifiers
    case purchases
    case usageData = "usage"
    case diagnostics
    case surroundings
    case body
    case otherData = "other"

    var id: String { rawValue }

    /// Apple's name, e.g. "Contact Info".
    var name: String {
        switch self {
        case .contactInfo: String(localized: "Contact Info")
        case .healthAndFitness: String(localized: "Health & Fitness")
        case .financialInfo: String(localized: "Financial Info")
        case .location: String(localized: "Location")
        case .sensitiveInfo: String(localized: "Sensitive Info")
        case .contacts: String(localized: "Contacts")
        case .userContent: String(localized: "User Content")
        case .browsingHistory: String(localized: "Browsing History")
        case .searchHistory: String(localized: "Search History")
        case .identifiers: String(localized: "Identifiers")
        case .purchases: String(localized: "Purchases")
        case .usageData: String(localized: "Usage Data")
        case .diagnostics: String(localized: "Diagnostics")
        case .surroundings: String(localized: "Surroundings")
        case .body: String(localized: "Body")
        case .otherData: String(localized: "Other Data")
        }
    }

    /// The category's data types, in App Store Connect's order.
    var types: [PrivacyDataType] {
        PrivacyDataType.allCases.filter { $0.category == self }
    }
}
