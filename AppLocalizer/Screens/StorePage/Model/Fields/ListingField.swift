//
//  ListingField.swift
//  AppLocalizer
//

import Foundation

/// A text field of the App Store listing, in the coverage grid's column
/// order. Raw values are App Store Connect's attribute names on
/// `appInfoLocalizations` (app level) and `appStoreVersionLocalizations`
/// (version level), and also the keys in exported files.
enum ListingField: String, CaseIterable, Identifiable, Hashable, Sendable, Codable {
    case name
    case subtitle
    case privacyPolicyURL = "privacyPolicyUrl"
    case promotionalText
    case description
    case keywords
    case whatsNew
    case supportURL = "supportUrl"
    case marketingURL = "marketingUrl"

    var id: String { rawValue }

    /// The editor's label, e.g. "Promotional Text".
    var title: String {
        switch self {
        case .name: String(localized: "Name")
        case .subtitle: String(localized: "Subtitle")
        case .privacyPolicyURL: String(localized: "Privacy Policy URL")
        case .promotionalText: String(localized: "Promotional Text")
        case .description: String(localized: "Description")
        case .keywords: String(localized: "Keywords")
        case .whatsNew: String(localized: "What’s New")
        case .supportURL: String(localized: "Support URL")
        case .marketingURL: String(localized: "Marketing URL")
        }
    }

    /// The coverage grid's column title, e.g. "Promo".
    var shortTitle: String {
        switch self {
        case .name: String(localized: "Name")
        case .subtitle: String(localized: "Subtitle")
        case .privacyPolicyURL: String(localized: "Privacy")
        case .promotionalText: String(localized: "Promo")
        case .description: String(localized: "Description")
        case .keywords: String(localized: "Keywords")
        case .whatsNew: String(localized: "What’s New")
        case .supportURL: String(localized: "Support")
        case .marketingURL: String(localized: "Marketing")
        }
    }

    /// The title mid-sentence, as in "French subtitle is 33 characters".
    var sentenceTitle: String {
        switch self {
        case .name: String(localized: "name")
        case .subtitle: String(localized: "subtitle")
        case .privacyPolicyURL: String(localized: "privacy policy URL")
        case .promotionalText: String(localized: "promotional text")
        case .description: String(localized: "description")
        case .keywords: String(localized: "keywords")
        case .whatsNew: String(localized: "What’s New")
        case .supportURL: String(localized: "support URL")
        case .marketingURL: String(localized: "marketing URL")
        }
    }

    /// Name, subtitle and privacy policy URL belong to the app and are
    /// shared by every version; the rest belong to one version.
    var level: ListingFieldLevel {
        switch self {
        case .name, .subtitle, .privacyPolicyURL: .app
        case .promotionalText, .description, .keywords, .whatsNew, .supportURL, .marketingURL: .version
        }
    }

    /// App Store Connect's limit. URLs have none worth counting against.
    var limit: ListingTextLimit? {
        switch self {
        case .name, .subtitle: ListingTextLimit(30)
        case .promotionalText: ListingTextLimit(170)
        case .description, .whatsNew: ListingTextLimit(4000)
        case .keywords: ListingTextLimit(100, unit: .bytes)
        case .privacyPolicyURL, .supportURL, .marketingURL: nil
        }
    }

    var isURL: Bool {
        switch self {
        case .privacyPolicyURL, .supportURL, .marketingURL: true
        default: false
        }
    }

    /// Whether App Store Connect needs it before submitting for review.
    /// Empty fields show as missing either way; this is for wording.
    var isRequired: Bool {
        switch self {
        case .name, .privacyPolicyURL, .description, .keywords, .whatsNew, .supportURL: true
        case .subtitle, .promotionalText, .marketingURL: false
        }
    }

    /// Description and What's New are edited in a text area.
    var isMultiline: Bool {
        self == .description || self == .whatsNew
    }

    /// URLs are copied as they are; everything else goes to a translator.
    var isTranslatable: Bool { !isURL }

    /// What's New doesn't exist on an app's first version.
    func applies(toFirstVersion isFirstVersion: Bool) -> Bool {
        !(isFirstVersion && self == .whatsNew)
    }

    static let appLevel: [ListingField] = allCases.filter { $0.level == .app }
    static let versionLevel: [ListingField] = allCases.filter { $0.level == .version }
}
