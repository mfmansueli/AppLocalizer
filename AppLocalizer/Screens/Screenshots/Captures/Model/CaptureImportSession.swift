//
//  CaptureImportSession.swift
//  AppLocalizer
//

import Foundation

/// An import at the matching step (design `capt-match`): where the files
/// came from, each file's match, and what the person chose for the rows
/// that need them. Nothing is copied or uploaded until Import.
struct CaptureImportSession: Hashable, Sendable {
    var source: CaptureSource
    /// "~/Developer/Lumen/fastlane/screenshots".
    var location: String
    var rows: [CaptureMatchRow]

    var fileCount: Int { rows.reduce(0) { $0 + $1.files.count } }

    var matchedCount: Int { rows.filter { !$0.needsYou }.reduce(0) { $0 + $1.files.count } }

    /// Rows that need a decision.
    var needsYouCount: Int { rows.count(where: \.needsYou) }

    /// What Import brings in, with every choice applied.
    var items: [CaptureImportItem] { rows.flatMap(\.items) }

    /// The slots the template grows to for "Add slot 6".
    var slotsNeeded: Int? { rows.compactMap(\.slotsNeeded).max() }

    mutating func choose(_ choice: CaptureChoice, forRow id: CaptureMatchRow.ID) {
        guard let index = rows.firstIndex(where: { $0.id == id }), rows[index].options.contains(where: { $0.choice == choice }) else { return }
        rows[index].choice = choice
    }

    // MARK: - Words

    /// "fastlane snapshot output · 55 files".
    var title: String {
        switch source {
        case .fastlane: String(localized: "fastlane snapshot output · \(fileCount) files")
        case .xcodeResults: String(localized: "Xcode test results · \(fileCount) attachments")
        case .folder: String(localized: "Folder · \(fileCount) files")
        case .appStoreConnect: String(localized: "App Store Connect · \(fileCount) live screenshots")
        case .autopilot: String(localized: "Autopilot · \(fileCount) captures")
        }
    }

    /// "52 matched".
    var matchedText: String { String(localized: "\(matchedCount) matched") }

    /// "3 need you".
    var needsYouText: String { String(localized: "\(needsYouCount) need you") }

    /// "10 locales · 2 display types", among the matched files.
    var spreadText: String {
        let placements = rows.compactMap { $0.needsYou ? nil : $0.placement }
        let locales = Set(placements.map(\.locale)).count
        let displays = Set(placements.map(\.displayType)).count
        let localeText = locales == 1 ? String(localized: "1 locale") : String(localized: "\(locales) locales")
        let displayText = displays == 1 ? String(localized: "1 display type") : String(localized: "\(displays) display types")
        return "\(localeText) · \(displayText)"
    }

    /// "Import 52 Captures".
    var importTitle: String {
        items.count == 1 ? String(localized: "Import 1 Capture") : String(localized: "Import \(items.count) Captures")
    }

    /// App Store Connect's screenshots are finished marketing images.
    var warning: String? {
        guard source == .appStoreConnect else { return nil }
        return String(localized: """
        These are the screenshots live in App Store Connect. They may already have captions, which the template \
        would then draw a second time.
        """)
    }
}
