//
//  ListingField+Transfer.swift
//  AppLocalizer
//

import Foundation

// Exported files are for translators anywhere, so their hints are in
// English rather than the app's language.
extension ListingField {
    /// Matches a field name from an imported file: the API name
    /// (`whatsNew`), the title ("What's New") or the column title ("Promo"),
    /// ignoring case, spaces and punctuation.
    init?(transferName: String) {
        let name = Self.simplified(transferName)
        guard !name.isEmpty else { return nil }
        let match = Self.allCases.first { field in
            [field.rawValue, field.englishTitle, field.englishShortTitle].contains { Self.simplified($0) == name }
        }
        guard let match else { return nil }
        self = match
    }

    /// The CSV's limit column: "30 characters", "100 bytes", or empty.
    var limitDescription: String {
        guard let limit else { return "" }
        return "\(limit.maximum) \(limit.unit == .bytes ? "bytes" : "characters")"
    }

    /// The XLIFF note, e.g. "Subtitle · 30 characters" or
    /// "Keywords · 100 bytes, comma-separated, no spaces".
    var translatorNote: String {
        switch self {
        case .keywords: "\(englishTitle) · \(limitDescription), comma-separated, no spaces"
        case .privacyPolicyURL, .supportURL, .marketingURL: "\(englishTitle) · a full https:// address, copied as is"
        default: "\(englishTitle) · \(limitDescription)"
        }
    }

    private var englishTitle: String {
        switch self {
        case .name: "Name"
        case .subtitle: "Subtitle"
        case .privacyPolicyURL: "Privacy Policy URL"
        case .promotionalText: "Promotional Text"
        case .description: "Description"
        case .keywords: "Keywords"
        case .whatsNew: "What's New"
        case .supportURL: "Support URL"
        case .marketingURL: "Marketing URL"
        }
    }

    private var englishShortTitle: String {
        switch self {
        case .privacyPolicyURL: "Privacy"
        case .promotionalText: "Promo"
        case .supportURL: "Support"
        case .marketingURL: "Marketing"
        default: englishTitle
        }
    }

    private static func simplified(_ name: String) -> String {
        String(name.lowercased().filter { $0.isLetter || $0.isNumber })
    }
}
