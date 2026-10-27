//
//  ListingCoverageSummary.swift
//  AppLocalizer
//

import Foundation

/// The counts behind the Store Page summary line and the overview card:
/// "10 of 39 locales · 11 missing · 1 over the limit · 1 machine-translated
/// · 1 not pushed". Each cell counts once, by its displayed state.
struct ListingCoverageSummary: Hashable, Sendable {
    var localeCount = 0
    var cellCount = 0
    /// Cells with text, whatever their state.
    var filledCount = 0
    var missingCount = 0
    /// Over the limit or an invalid URL.
    var overLimitCount = 0
    var machineTranslatedCount = 0
    var editedCount = 0
    var proposedCount = 0

    /// Edited or proposed by an assistant, not pushed yet.
    var notPushedCount: Int { editedCount + proposedCount }

    /// Every App Store locale, the "of 39".
    var catalogCount: Int { StoreLocaleCatalog.all.count }

    /// Share of cells with text, 0…1.
    var completeness: Double {
        cellCount == 0 ? 0 : Double(filledCount) / Double(cellCount)
    }

    /// Completeness as a whole percentage, for the overview card.
    var completenessPercent: Int {
        Int((completeness * 100).rounded())
    }

    var line: String {
        String(localized: """
        \(localeCount) of \(catalogCount) locales · \(missingCount) missing · \(overLimitCount) over the limit · \
        \(machineTranslatedCount) machine-translated · \(notPushedCount) not pushed
        """)
    }

    mutating func add(_ state: ListingCoverageState, hasText: Bool) {
        guard state != .notApplicable else { return }
        cellCount += 1
        if hasText { filledCount += 1 }
        switch state {
        case .missing: missingCount += 1
        case .overLimit, .invalidURL: overLimitCount += 1
        case .machineTranslated: machineTranslatedCount += 1
        case .edited: editedCount += 1
        case .proposed: proposedCount += 1
        case .filled, .notApplicable: break
        }
    }
}
