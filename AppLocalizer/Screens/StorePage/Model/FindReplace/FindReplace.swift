//
//  FindReplace.swift
//  AppLocalizer
//

import Foundation

/// Searching listing text, for "Find and replace across locales".
enum FindReplace {
    /// Every editable field in scope that contains the search text,
    /// locales in display order (primary first), fields in column order.
    static func matches(in listing: StoreListing, for query: FindReplaceQuery) -> [FindReplaceMatch] {
        guard !query.isEmpty else { return [] }
        let locales = listing.displayLocales.filter { query.locales?.contains($0) ?? true }
        let fields = listing.fields.filter { query.fields.contains($0) && listing.canEdit($0) }
        return locales.flatMap { locale in
            fields.compactMap { field -> FindReplaceMatch? in
                let value = listing.value(field, in: locale)
                let ranges = occurrences(of: query.find, in: value, caseSensitive: query.isCaseSensitive, wholeWords: query.matchesWholeWords)
                guard !ranges.isEmpty else { return nil }
                return FindReplaceMatch(
                    key: ListingFieldKey(locale, field),
                    originalValue: value,
                    ranges: ranges,
                    replacement: query.replacement,
                    replacedValue: replacing(ranges, in: value, with: query.replacement)
                )
            }
        }
    }

    /// Non-overlapping occurrences of `find` in `text`.
    static func occurrences(of find: String, in text: String, caseSensitive: Bool, wholeWords: Bool) -> [Range<String.Index>] {
        guard !find.isEmpty else { return [] }
        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        var ranges: [Range<String.Index>] = []
        var searchStart = text.startIndex
        while searchStart < text.endIndex,
              let range = text.range(of: find, options: options, range: searchStart..<text.endIndex)
        {
            if !wholeWords || isWholeWord(range, in: text) { ranges.append(range) }
            searchStart = range.upperBound
        }
        return ranges
    }

    static func replacing(_ ranges: [Range<String.Index>], in text: String, with replacement: String) -> String {
        var result = ""
        var cursor = text.startIndex
        for range in ranges {
            result += text[cursor..<range.lowerBound]
            result += replacement
            cursor = range.upperBound
        }
        result += text[cursor...]
        return result
    }

    private static func isWholeWord(_ range: Range<String.Index>, in text: String) -> Bool {
        let isWordCharacter: (Character) -> Bool = { $0.isLetter || $0.isNumber || $0 == "_" }
        if range.lowerBound > text.startIndex, isWordCharacter(text[text.index(before: range.lowerBound)]) { return false }
        if range.upperBound < text.endIndex, isWordCharacter(text[range.upperBound]) { return false }
        return true
    }
}
