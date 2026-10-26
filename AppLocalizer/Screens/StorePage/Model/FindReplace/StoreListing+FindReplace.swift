//
//  StoreListing+FindReplace.swift
//  AppLocalizer
//

import Foundation

extension StoreListing {
    func matches(for query: FindReplaceQuery) -> [FindReplaceMatch] {
        FindReplace.matches(in: self, for: query)
    }

    /// Applies the selected matches as your edits ("Replace All" passes
    /// every match). A match whose field changed since the search is
    /// skipped. Over-limit results are applied and then blocked in Review &
    /// Push. Returns how many fields changed.
    @discardableResult
    mutating func replace(_ matches: some Sequence<FindReplaceMatch>) -> Int {
        var count = 0
        for match in matches where value(match.key.field, in: match.key.locale) == match.originalValue {
            edit(match.key.field, in: match.key.locale, to: match.replacedValue)
            count += 1
        }
        return count
    }
}
