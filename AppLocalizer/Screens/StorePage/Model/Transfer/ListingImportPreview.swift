//
//  ListingImportPreview.swift
//  AppLocalizer
//

import Foundation

/// The import sheet: what a translator's file would change, compared with
/// the current values, plus the problems that keep some values out.
///
/// - One change per locale × field whose new value differs from the
///   current one, in file order, all selected.
/// - Empty values in the file mean "not translated" and are ignored.
/// - Locale codes are matched tolerantly (`de` → German); unknown or
///   ambiguous ones (`pt`) are listed and skipped.
/// - Over-limit values and invalid URLs are listed and skipped, so nothing
///   that can't be pushed comes in.
/// - When a cell appears twice, the first value wins.
struct ListingImportPreview: Hashable, Sendable {
    let fileName: String?
    private(set) var changes: [ListingImportChange]
    let problems: [ListingImportProblem]

    init(document: ListingTransferDocument, listing: StoreListing, fileName: String? = nil) {
        self.fileName = fileName
        var builder = Builder(listing: listing)
        for entry in document.entries {
            builder.add(entry)
        }
        changes = builder.changes
        problems = builder.problems
    }

    var selectedChanges: [ListingImportChange] { changes.filter(\.isSelected) }

    /// Locales with at least one change.
    var localeCount: Int { Set(changes.map(\.key.locale)).count }

    /// "Lumen-1.4-translations.xliff · 5 changes in 5 locales · 2 problems".
    var summary: String {
        let changeText = changes.count == 1 ? String(localized: "1 change") : String(localized: "\(changes.count) changes")
        let localeText = localeCount == 1 ? String(localized: "in 1 locale") : String(localized: "in \(localeCount) locales")
        var parts = ["\(changeText) \(localeText)"]
        if !problems.isEmpty {
            parts.append(problems.count == 1 ? String(localized: "1 problem") : String(localized: "\(problems.count) problems"))
        }
        if let fileName { parts.insert(fileName, at: 0) }
        return parts.joined(separator: " · ")
    }

    /// "Apply 5 Changes", counting the selected ones.
    var applyTitle: String {
        let count = selectedChanges.count
        return count == 1 ? String(localized: "Apply 1 Change") : String(localized: "Apply \(count) Changes")
    }

    mutating func setSelected(_ id: ListingFieldKey, _ isSelected: Bool) {
        guard let index = changes.firstIndex(where: { $0.id == id }) else { return }
        changes[index].isSelected = isSelected
    }

    mutating func toggle(_ id: ListingFieldKey) {
        guard let index = changes.firstIndex(where: { $0.id == id }) else { return }
        changes[index].isSelected.toggle()
    }

    mutating func selectAll(_ isSelected: Bool) {
        for index in changes.indices {
            changes[index].isSelected = isSelected
        }
    }

    private struct UnknownLocale {
        let code: String
        let suggestions: [StoreLocale]
        var count: Int
    }

    /// Sorts entries into changes and problems, one at a time.
    private struct Builder {
        let listing: StoreListing
        var changes: [ListingImportChange] = []
        private var seen = Set<ListingFieldKey>()
        private var unknownLocales: [UnknownLocale] = []
        private var unknownFields: [(name: String, count: Int)] = []
        private var notEditableCount = 0
        private var valueProblems: [ListingImportProblem] = []

        init(listing: StoreListing) {
            self.listing = listing
        }

        var problems: [ListingImportProblem] {
            unknownLocales.map { .unknownLocale(code: $0.code, suggestions: $0.suggestions, skippedCount: $0.count) }
                + unknownFields.map { .unknownField(name: $0.name, skippedCount: $0.count) }
                + (notEditableCount > 0 ? [.notEditable(version: listing.version.versionString, skippedCount: notEditableCount)] : [])
                + valueProblems
        }

        mutating func add(_ entry: ListingTransferEntry) {
            let value = entry.value
            guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            let match = StoreLocaleCatalog.resolve(entry.localeCode)
            guard let locale = match.locale else { return countUnknownLocale(entry.localeCode, match: match) }
            guard let field = ListingField(transferName: entry.fieldName) else { return countUnknownField(entry.fieldName) }
            guard listing.canEdit(field) else {
                notEditableCount += 1
                return
            }
            let key = ListingFieldKey(locale, field)
            guard seen.insert(key).inserted else { return }
            switch ListingFieldValidator.validate(value, for: field) {
            case let .overLimit(count, limit): valueProblems.append(.overLimit(key: key, count: count, limit: limit))
            case .invalidURL: valueProblems.append(.invalidURL(key: key))
            case .valid, .empty:
                let current = listing.value(field, in: locale)
                if value != current { changes.append(ListingImportChange(key: key, oldValue: current, newValue: value)) }
            }
        }

        private mutating func countUnknownLocale(_ code: String, match: StoreLocaleMatch) {
            if let index = unknownLocales.firstIndex(where: { $0.code == code }) {
                unknownLocales[index].count += 1
                return
            }
            var suggestions: [StoreLocale] = []
            if case let .ambiguous(candidates) = match { suggestions = candidates }
            unknownLocales.append(UnknownLocale(code: code, suggestions: suggestions, count: 1))
        }

        private mutating func countUnknownField(_ name: String) {
            if let index = unknownFields.firstIndex(where: { $0.name == name }) {
                unknownFields[index].count += 1
            } else {
                unknownFields.append((name, 1))
            }
        }
    }
}
