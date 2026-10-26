//
//  ListingCoverageCell.swift
//  AppLocalizer
//

import Foundation

/// One cell of the coverage grid. Clicking it opens the editor at that
/// locale and field.
struct ListingCoverageCell: Identifiable, Hashable, Sendable {
    let key: ListingFieldKey
    let state: ListingCoverageState

    var id: ListingFieldKey { key }

    /// The cell's text next to its icon: "20/30", "383", "88 B", "" for a
    /// filled URL, "31/30", "Invalid", "Missing", "MT", "Edited", "Proposed".
    var text: String {
        switch state {
        case let .filled(count):
            filledText(count)
        case let .overLimit(count, limit):
            "\(count)/\(limit.maximum)"
        case .invalidURL:
            String(localized: "Invalid")
        case .missing:
            String(localized: "Missing")
        case .machineTranslated:
            String(localized: "MT")
        case .edited:
            String(localized: "Edited")
        case .proposed:
            String(localized: "Proposed")
        case .notApplicable:
            "—"
        }
    }

    /// "German, Subtitle: over the limit".
    var accessibilityLabel: String {
        "\(key.locale.name), \(key.field.title): \(state.accessibilityDescription)"
    }

    private func filledText(_ count: Int) -> String {
        let field = key.field
        guard let limit = field.limit else { return "" }
        switch field {
        case .description, .whatsNew: return count.formatted()
        case .keywords: return String(localized: "\(count) B")
        default: return "\(count)/\(limit.maximum)"
        }
    }
}
