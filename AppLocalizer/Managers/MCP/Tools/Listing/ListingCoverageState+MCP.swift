//
//  ListingCoverageState+MCP.swift
//  AppLocalizer
//

import Foundation

extension ListingCoverageState {
    /// What an assistant should know about a field beyond its text, e.g.
    /// "missing" or "proposed by Claude Code, waiting in review"; nil when
    /// it's simply filled in.
    var assistantNote: String? {
        switch self {
        case .filled, .notApplicable: nil
        case .missing: "missing"
        case let .overLimit(count, limit): "over the limit: \(count) of \(limit.maximum) \(limit.unit == .bytes ? "bytes" : "characters")"
        case .invalidURL: "not a valid https URL"
        case .machineTranslated: "machine-translated, not reviewed yet"
        case .edited: "changed by the person, waiting in review"
        case let .proposed(client): "proposed by \(client), waiting in review"
        }
    }
}
