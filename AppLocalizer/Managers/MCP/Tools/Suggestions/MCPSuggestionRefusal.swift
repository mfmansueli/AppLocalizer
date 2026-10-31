//
//  MCPSuggestionRefusal.swift
//  AppLocalizer
//

import Foundation

/// Why `suggest_fields` didn't queue an item, as a code the assistant can
/// branch on and a sentence saying what to do.
enum MCPSuggestionRefusal: Error, Hashable, Sendable {
    case overLimit(count: Int, limit: ListingTextLimit)
    case unknownField(String, known: [String])
    case unknownLocale(String)
    /// The version is in review or live.
    case locked(version: String)
    case notPermitted(MCPProposalKind)
    /// Empty, not an https URL, or not one of a picked field's choices.
    case invalidValue(String)
    /// Not one of an Age Rating question's or Accessibility feature's
    /// answers.
    case invalidAnswer(String)
    /// The person stopped receiving the run's suggestions.
    case runStopped

    var code: String {
        switch self {
        case .overLimit: "over_limit"
        case .unknownField: "unknown_field"
        case .unknownLocale: "unknown_locale"
        case .locked: "locked"
        case .notPermitted: "not_permitted"
        case .invalidValue: "invalid_value"
        case .invalidAnswer: "invalid_answer"
        case .runStopped: "run_stopped"
        }
    }

    var reason: String {
        switch self {
        case let .overLimit(count, limit):
            String(localized: "Over the limit: \(count) of \(limit.maximum) \(limit.unit.name). Shorten it and send it again.")
        case let .unknownField(name, known):
            String(localized: "There’s no field “\(name)” here. The fields are \(known.joined(separator: ", ")).")
        case let .unknownLocale(message):
            message
        case let .locked(version):
            String(localized: "Version \(version) is in review or live, so this field can’t change.")
        case let .notPermitted(kind):
            kind.refusal
        case let .invalidValue(message), let .invalidAnswer(message):
            message
        case .runStopped:
            String(localized: "The person stopped receiving this run’s suggestions in AppLocalizer. Don’t send more for it.")
        }
    }

    /// The result's fields: status, code, reason, and the count and limit
    /// for over_limit.
    var json: [String: JSONValue] {
        var result: [String: JSONValue] = ["status": "refused", "code": .string(code), "reason": .string(reason)]
        if case let .overLimit(count, limit) = self {
            result["count"] = .int(count)
            result["limit"] = ["max": .int(limit.maximum), "unit": .string(limit.unit == .bytes ? "bytes" : "characters")]
        }
        return result
    }
}
