//
//  ListingCoverageState.swift
//  AppLocalizer
//

import Foundation

/// What one coverage-grid cell shows.
///
/// When several apply, the first wins:
/// 1. over the limit or invalid URL: it can't be pushed, so it's the most
///    urgent;
/// 2. proposed by an assistant (pending);
/// 3. machine-translated, not reviewed (pending or already pushed);
/// 4. edited, not pushed;
/// 5. missing;
/// 6. filled.
///
/// A read-only field only shows filled or missing. What's New on a first
/// version is not applicable.
enum ListingCoverageState: Hashable, Sendable {
    /// Has text and nothing to do. `count` is in the field's unit.
    case filled(count: Int)
    case missing
    case overLimit(count: Int, limit: ListingTextLimit)
    case invalidURL
    case machineTranslated
    case edited
    case proposed(client: String)
    case notApplicable

    init(draft: ListingFieldDraft, field: ListingField, isEditable: Bool, applies: Bool = true) {
        guard applies else {
            self = .notApplicable
            return
        }
        let value = draft.local
        let count = field.limit?.count(value) ?? ListingTextMeasure.characters(in: value)
        guard isEditable else {
            self = value.isEmpty ? .missing : .filled(count: count)
            return
        }
        switch ListingFieldValidator.validate(value, for: field) {
        case let .overLimit(count, limit):
            self = .overLimit(count: count, limit: limit)
        case .invalidURL:
            self = .invalidURL
        case .valid, .empty:
            if let client = draft.proposedBy, draft.isPending {
                self = .proposed(client: client)
            } else if draft.isMachineTranslated {
                self = .machineTranslated
            } else if draft.isPending {
                self = .edited
            } else {
                self = value.isEmpty ? .missing : .filled(count: count)
            }
        }
    }

    /// Edited or proposed: counted as "not pushed" in the summary line.
    var isNotPushed: Bool {
        switch self {
        case .edited, .proposed: true
        default: false
        }
    }

    /// Over the limit or an invalid URL: counted as "over the limit".
    var isProblem: Bool {
        switch self {
        case .overLimit, .invalidURL: true
        default: false
        }
    }

    /// The state as VoiceOver says it after "German, Subtitle: ".
    var accessibilityDescription: String {
        switch self {
        case .filled: String(localized: "filled")
        case .missing: String(localized: "missing")
        case .overLimit: String(localized: "over the limit")
        case .invalidURL: String(localized: "invalid URL")
        case .machineTranslated: String(localized: "machine-translated, not reviewed")
        case .edited: String(localized: "edited, not pushed")
        case let .proposed(client): String(localized: "proposed by \(client)")
        case .notApplicable: String(localized: "not used in a first version")
        }
    }
}
