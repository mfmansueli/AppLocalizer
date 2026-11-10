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

    /// The line under the page's title.
    func summary(appName: String, version: String?) -> String {
        let version = version ?? ""
        switch self {
        case .general:
            return version.isEmpty
                ? String(localized: "Copyright, categories and how the version is released.")
                : String(localized: "Copyright, categories and how \(version) is released.")
        case .ageRating: return String(localized: "Apple’s questionnaire. Apple works out \(appName)’s age rating from these answers.")
        case .accessibility: return String(localized: "Accessibility Nutrition Labels: what people can do with each feature, per device.")
        case .appPrivacy: return String(localized: "What data \(appName) collects and why.")
        case .appReview:
            return version.isEmpty
                ? String(localized: "Who Apple contacts and what reviewers need to test the version.")
                : String(localized: "Who Apple contacts and what reviewers need to test \(version).")
        case .exportCompliance: return String(localized: "Whether \(appName) uses encryption that needs documents.")
        }
    }

    /// In the page's bar: what it changes on the App Store.
    func whereShown(appName: String) -> String {
        switch self {
        case .general: String(localized: "On the App Store: the category under the name, and the Information section.")
        case .ageRating: String(localized: "On the App Store: the age under the name, such as 4+.")
        case .accessibility: String(localized: "On the App Store: the Accessibility section lists what \(appName) supports.")
        case .appPrivacy: String(localized: "On the App Store: the App Privacy section.")
        case .appReview: String(localized: "Not on the App Store. Only App Review reads it.")
        case .exportCompliance: String(localized: "Not on the App Store.")
        }
    }
}
