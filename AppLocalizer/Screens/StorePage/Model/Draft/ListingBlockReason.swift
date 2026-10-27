//
//  ListingBlockReason.swift
//  AppLocalizer
//

import Foundation

/// Why a pending change stays in the review sheet but can't be pushed.
enum ListingBlockReason: Hashable, Sendable {
    case overLimit(count: Int, limit: ListingTextLimit)
    case invalidURL
    /// You and an assistant both changed the field; pick one first.
    case conflict(client: String)

    /// The line shown on the blocked row.
    var message: String {
        switch self {
        case .overLimit: String(localized: "Over the limit · fix it in Store Page")
        case .invalidURL: String(localized: "Not a valid https URL")
        case let .conflict(client): String(localized: "You and \(client) both changed this field. Pick the one to push.")
        }
    }
}
