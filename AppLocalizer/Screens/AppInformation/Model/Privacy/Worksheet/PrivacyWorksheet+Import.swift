//
//  PrivacyWorksheet+Import.swift
//  AppLocalizer
//

import Foundation

// "Import from fastlane": the file's answers become the person's.
extension PrivacyWorksheet {
    /// Replaces the answers with the imported ones, all the person's. Types
    /// the file doesn't name become not collected; suggestions waiting for
    /// review are kept as conflicts where they differ.
    mutating func importAnswers(_ imported: PrivacyFastlaneImport) {
        isStarted = true
        collects = .yours(imported.collects)
        var newEntries: [PrivacyDataType: PrivacyTypeEntry] = [:]
        for type in PrivacyDataType.allCases {
            let answer = imported.answers[type] ?? .notCollected
            let old = entries[type]
            guard answer != .notCollected || old != nil else { continue }
            var entry = PrivacyTypeEntry.yours(answer)
            if let suggestion = old?.suggestion, suggestion.answer != answer, old?.status == .unreviewed {
                entry.conflict = suggestion
            } else {
                entry.suggestion = old?.suggestion
            }
            newEntries[type] = entry
        }
        entries = newEntries
    }
}
