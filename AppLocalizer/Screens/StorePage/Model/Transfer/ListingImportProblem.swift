//
//  ListingImportProblem.swift
//  AppLocalizer
//

import Foundation

/// Something in an imported file that won't be applied, listed under the
/// diff before anything changes. Locale and field problems are warnings
/// (yellow); values that break a rule are errors (red).
enum ListingImportProblem: Hashable, Sendable {
    /// The code isn't an App Store locale. `suggestions` are the locales it
    /// could mean (`pt` → Brazil, Portugal).
    case unknownLocale(code: String, suggestions: [StoreLocale], skippedCount: Int)
    case unknownField(name: String, skippedCount: Int)
    /// Version fields while the version is read-only.
    case notEditable(version: String, skippedCount: Int)
    case overLimit(key: ListingFieldKey, count: Int, limit: ListingTextLimit)
    case invalidURL(key: ListingFieldKey)

    var isError: Bool {
        switch self {
        case .overLimit, .invalidURL: true
        case .unknownLocale, .unknownField, .notEditable: false
        }
    }

    var message: String {
        switch self {
        case let .unknownLocale(code, suggestions, skippedCount):
            unknownLocaleMessage(code: code, suggestions: suggestions, skippedCount: skippedCount)
        case let .unknownField(name, skippedCount):
            String(localized: "“\(name)” isn’t a store page field.") + " " + Self.skipped(skippedCount, of: .values)
        case let .notEditable(version, skippedCount):
            String(localized: "Version \(version) is read-only.") + " " + Self.skipped(skippedCount, of: .fields)
        case let .overLimit(key, count, limit):
            overLimitMessage(key: key, count: count, limit: limit)
        case let .invalidURL(key):
            String(localized: "\(key.locale.name) \(key.field.sentenceTitle) isn’t a full https:// address. Skipped.")
        }
    }

    private enum Noun { case fields, values }

    /// "“pt” isn’t an App Store locale. Did you mean Portuguese (Brazil) or
    /// Portuguese (Portugal)? 9 fields skipped."
    private func unknownLocaleMessage(code: String, suggestions: [StoreLocale], skippedCount: Int) -> String {
        let skipped = Self.skipped(skippedCount, of: .fields)
        guard !code.isEmpty else {
            return String(localized: "Part of the file has no target language.") + " " + skipped
        }
        let lead = String(localized: "“\(code)” isn’t an App Store locale.")
        let names = suggestions.map(\.name)
        guard let last = names.last else { return "\(lead) \(skipped)" }
        let options = names.count == 1 ? last : names.dropLast().joined(separator: ", ") + String(localized: " or ") + last
        return "\(lead) " + String(localized: "Did you mean \(options)?") + " \(skipped)"
    }

    /// "French subtitle is 33 characters; the limit is 30. Skipped."
    private func overLimitMessage(key: ListingFieldKey, count: Int, limit: ListingTextLimit) -> String {
        let subject = "\(key.locale.name) \(key.field.sentenceTitle)"
        return key.field == .keywords
            ? String(localized: "\(subject) are \(count) \(limit.unit.name); the limit is \(limit.maximum). Skipped.")
            : String(localized: "\(subject) is \(count) \(limit.unit.name); the limit is \(limit.maximum). Skipped.")
    }

    private static func skipped(_ count: Int, of noun: Noun) -> String {
        switch (noun, count == 1) {
        case (.fields, true): String(localized: "1 field skipped.")
        case (.fields, false): String(localized: "\(count) fields skipped.")
        case (.values, true): String(localized: "1 value skipped.")
        case (.values, false): String(localized: "\(count) values skipped.")
        }
    }
}
