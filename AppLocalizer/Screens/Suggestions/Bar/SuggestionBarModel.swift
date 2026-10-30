//
//  SuggestionBarModel.swift
//  AppLocalizer
//

import Foundation

/// What the suggestion bar shows for one language (Store Page) or page
/// (App Information): the counts, the sources it can filter by, and the
/// second line's offers.
struct SuggestionBarModel: Hashable, Sendable {
    /// Open suggestions here, from every source.
    var openCount: Int
    /// Every suggestion here, open or decided.
    var totalCount: Int
    /// Open suggestions here, per source.
    var countsBySource: [SuggestionSourceFilter: Int]
    /// The assistant's segment name, e.g. "Claude Code".
    var assistantName: String?
    var filter: SuggestionSourceFilter
    var dismissedCount: Int
    /// Open suggestions the filter shows in every language, this one
    /// included; 0 on App Information.
    var everywhereCount: Int = 0

    /// What Accept All and Dismiss All act on.
    var visibleCount: Int {
        filter == .all ? openCount : countsBySource[filter, default: 0]
    }

    /// "5 suggestions", "All suggestions reviewed", "No suggestions".
    var countText: String {
        if openCount == 1 { return String(localized: "1 suggestion") }
        if openCount > 1 { return String(localized: "\(openCount) suggestions") }
        return totalCount > 0 ? String(localized: "All suggestions reviewed") : String(localized: "No suggestions")
    }

    /// All and the assistant always; the others while they have something
    /// open, or while they're the one chosen.
    var segments: [SuggestionSourceFilter] {
        SuggestionSourceFilter.allCases.filter { segment in
            segment == .all || segment == .assistant || segment == filter || countsBySource[segment, default: 0] > 0
        }
    }

    /// "Claude Code 3".
    func segmentTitle(_ segment: SuggestionSourceFilter) -> String {
        let count = segment == .all ? openCount : countsBySource[segment, default: 0]
        return "\(segment.title(assistant: assistantName)) \(count)"
    }

    /// Open in other languages.
    var otherScopesCount: Int { max(0, everywhereCount - visibleCount) }

    /// The line under the bar shows once there's anything here at all.
    var hasSecondLine: Bool { totalCount > 0 }
}
