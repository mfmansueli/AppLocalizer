//
//  MCPPlanSkip.swift
//  AppLocalizer
//

import Foundation

/// Why `begin_suggestions` left a planned field out of the run, as a code
/// the assistant can branch on.
enum MCPPlanSkip: Error, Hashable, Sendable {
    /// The person changed it in AppLocalizer and hasn't pushed it yet.
    case changedByYou
    /// An Ask for one page is still sending suggestions for it.
    case inAnotherRequest
    /// The assistant's own suggestion for it still waits for the person.
    case alreadySuggested
    /// What `suggest_fields` would refuse: locked, unknown, not permitted.
    case refused(MCPSuggestionRefusal)

    var code: String {
        switch self {
        case .changedByYou: "changed_by_you"
        case .inAnotherRequest: "in_another_request"
        case .alreadySuggested: "already_suggested"
        case let .refused(refusal): refusal.code
        }
    }

    var reason: String {
        switch self {
        case .changedByYou: String(localized: "The person changed it in AppLocalizer and hasn’t pushed it yet.")
        case .inAnotherRequest: String(localized: "Suggestions for it are still coming from an Ask for one page.")
        case .alreadySuggested: String(localized: "Your suggestion for it still waits for the person.")
        case let .refused(refusal): refusal.reason
        }
    }
}
