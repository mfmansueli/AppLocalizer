//
//  ListingFieldValidation.swift
//  AppLocalizer
//

import Foundation

/// The result of checking one value against its field's rules, with the
/// inline message under the field and what VoiceOver says.
enum ListingFieldValidation: Hashable, Sendable {
    case valid
    /// Nothing typed. Shows as missing, but doesn't block a push.
    case empty
    case overLimit(count: Int, limit: ListingTextLimit)
    /// URLs have to be full `https://` addresses with a host.
    case invalidURL

    /// Over-limit and invalid values stay pending but can't be pushed, so
    /// nothing reaches Apple only to be rejected.
    var isBlocking: Bool {
        switch self {
        case .overLimit, .invalidURL: true
        case .valid, .empty: false
        }
    }

    /// The inline error under the field, e.g. "2 characters over the limit."
    var message: String? {
        switch self {
        case let .overLimit(count, limit):
            let over = count - limit.maximum
            switch limit.unit {
            case .characters:
                return over == 1
                    ? String(localized: "1 character over the limit.")
                    : String(localized: "\(over) characters over the limit.")
            case .bytes:
                return String(localized: "\(over) bytes over. Each accented letter or CJK character counts as 2–3 bytes.")
            }
        case .invalidURL:
            return String(localized: "Use a full https:// address.")
        case .valid, .empty:
            return nil
        }
    }

    /// What VoiceOver says for the pill, e.g. "Over the limit, 31 of 30
    /// characters". Nil when there's nothing wrong.
    var accessibilityLabel: String? {
        switch self {
        case let .overLimit(count, limit):
            String(localized: "Over the limit, \(count) of \(limit.maximum) \(limit.unit.name)")
        case .invalidURL:
            String(localized: "Invalid URL")
        case .valid, .empty:
            nil
        }
    }
}
