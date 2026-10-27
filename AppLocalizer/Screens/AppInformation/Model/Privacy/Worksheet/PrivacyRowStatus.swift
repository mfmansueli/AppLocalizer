//
//  PrivacyRowStatus.swift
//  AppLocalizer
//

import Foundation

/// Where a worksheet answer stands. Only `unreviewed` doesn't count: it's
/// left out of the label preview, the checklist, the export and the
/// published snapshot.
enum PrivacyRowStatus: String, Hashable, Codable, Sendable {
    /// An assistant's suggestion nobody has looked at yet (purple).
    case unreviewed
    /// The person accepted the assistant's suggestion as it was.
    case accepted
    /// The person changed the assistant's suggestion.
    case edited
    /// The person's own answer.
    case yours
    /// The person rejected the suggestion: "not collected", theirs.
    case rejected

    var title: String {
        switch self {
        case .unreviewed: String(localized: "Unreviewed")
        case .accepted: String(localized: "Accepted")
        case .edited: String(localized: "Edited by you")
        case .yours: String(localized: "Yours")
        case .rejected: String(localized: "Suggestion rejected")
        }
    }

    /// Counts in the label, the checklist, the export and the snapshot.
    var isReviewed: Bool { self != .unreviewed }

    /// The answer is the assistant's (the row shows its tag), rather than
    /// the person's own.
    var isAssistants: Bool { self == .unreviewed || self == .accepted || self == .edited }
}
