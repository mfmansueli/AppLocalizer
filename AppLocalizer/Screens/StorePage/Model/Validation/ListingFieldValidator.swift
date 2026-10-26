//
//  ListingFieldValidator.swift
//  AppLocalizer
//

import Foundation

/// The same checks for every way a value arrives: typing, import,
/// translation, find and replace, or an assistant's proposal.
enum ListingFieldValidator {
    static func validate(_ value: String, for field: ListingField) -> ListingFieldValidation {
        validate(value, limit: field.limit, isURL: field.isURL)
    }

    static func validate(_ value: String, for field: InAppTextField) -> ListingFieldValidation {
        validate(value, limit: field.limit, isURL: false)
    }

    /// Whitespace-only counts as empty. The limit is checked on the value
    /// as typed, since App Store Connect counts every space.
    static func validate(_ value: String, limit: ListingTextLimit?, isURL: Bool) -> ListingFieldValidation {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .empty }
        if isURL, !isValidURL(value) { return .invalidURL }
        if let limit, limit.isExceeded(by: value) { return .overLimit(count: limit.count(value), limit: limit) }
        return .valid
    }

    /// A full `https://` address with a dotted host and no spaces, e.g.
    /// `https://lumen.example/privacy`. Surrounding whitespace is ignored;
    /// `lumen.example/support`, `http://…` and `https://localhost` aren't.
    static func isValidURL(_ value: String) -> Bool {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.lowercased().hasPrefix("https://"),
              !value.contains(where: \.isWhitespace),
              let components = URLComponents(string: value),
              components.scheme?.lowercased() == "https",
              let host = components.host
        else { return false }
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        return labels.count > 1 && labels.allSatisfy { !$0.isEmpty }
    }
}
