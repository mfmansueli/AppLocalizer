//
//  CaptureMatchRow.swift
//  AppLocalizer
//

import Foundation

/// One row of the matching table: a file matched to locale, display type
/// and slot, or files that need you, with why and the choices the design
/// offers. An ambiguous locale folder is one row for all its files.
struct CaptureMatchRow: Hashable, Sendable, Identifiable {
    var files: [CaptureCandidate]
    /// Where a matched file goes; for a row that needs you, where it goes
    /// once the locale is chosen (nil when that's what's unknown).
    var placement: Placement?
    var issue: CaptureIssue?
    var options: [Option]
    /// The option picked; the first one until the person picks.
    var choice: CaptureChoice?

    /// Locale, display type and 0-based slot.
    struct Placement: Hashable, Sendable {
        var locale: String
        var displayType: ScreenshotDisplayType
        var slot: Int
    }

    /// One entry of the row's menu.
    struct Option: Hashable, Sendable, Identifiable {
        var choice: CaptureChoice
        /// "Portuguese (Brazil)", "Use it, scaled up 113%".
        var title: String
        var id: String { choice.id }
    }

    var id: String { files.first?.path ?? "" }

    var needsYou: Bool { issue != nil }

    /// The file the row shows: the first of a folder's.
    var path: String { id }

    static func matched(_ file: CaptureCandidate, at placement: Placement) -> CaptureMatchRow {
        CaptureMatchRow(files: [file], placement: placement, issue: nil, options: [], choice: nil)
    }

    static func needsYou(_ files: [CaptureCandidate], issue: CaptureIssue, placement: Placement?, options: [Option]) -> CaptureMatchRow {
        CaptureMatchRow(files: files, placement: placement, issue: issue, options: options, choice: options.first?.choice)
    }

    /// The files this row imports and where, with the choice applied.
    var items: [CaptureImportItem] {
        guard let issue else {
            return files.compactMap { file in placement.map { CaptureImportItem(candidate: file, placement: $0) } }
        }
        switch (issue, choice) {
        case let (.ambiguousLocale, .locale(code)?):
            return files.compactMap { file in
                guard let display = file.displayType, let number = file.slotNumber else { return nil }
                return CaptureImportItem(candidate: file, placement: Placement(locale: code, displayType: display, slot: number - 1))
            }
        case (.smallerDevice, .scaleUp?), (.extraSlot, .addSlot?):
            return files.compactMap { file in placement.map { CaptureImportItem(candidate: file, placement: $0) } }
        default:
            return []
        }
    }

    /// The template needs this many slots for the row's choice.
    var slotsNeeded: Int? {
        if case let .addSlot(number)? = choice { return number }
        return nil
    }
}
