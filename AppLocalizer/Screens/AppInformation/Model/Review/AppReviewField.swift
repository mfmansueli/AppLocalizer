//
//  AppReviewField.swift
//  AppLocalizer
//

import Foundation

/// A field of the App Review page, with the `appStoreReviewDetails`
/// attribute that stores it.
enum AppReviewField: String, CaseIterable, Identifiable, Hashable, Sendable {
    case firstName
    case lastName
    case phone
    case email
    case signInRequired
    case userName
    case password
    case notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstName: String(localized: "First name")
        case .lastName: String(localized: "Last name")
        case .phone: String(localized: "Phone")
        case .email: String(localized: "Email")
        case .signInRequired: String(localized: "Sign-in required")
        case .userName: String(localized: "User name")
        case .password: String(localized: "Password")
        case .notes: String(localized: "Notes for the reviewer")
        }
    }

    var apiKey: String {
        switch self {
        case .firstName: "contactFirstName"
        case .lastName: "contactLastName"
        case .phone: "contactPhone"
        case .email: "contactEmail"
        case .signInRequired: "demoAccountRequired"
        case .userName: "demoAccountName"
        case .password: "demoAccountPassword"
        case .notes: "notes"
        }
    }

    static func field(apiKey: String) -> AppReviewField? {
        allCases.first { $0.apiKey == apiKey }
    }

    /// The notes' limit in App Store Connect.
    static let notesLimit = 4000
}
