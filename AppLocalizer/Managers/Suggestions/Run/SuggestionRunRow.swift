//
//  SuggestionRunRow.swift
//  AppLocalizer
//

import Foundation

/// One page's row on Suggest Everything's progress card: what the run
/// covers there and how much of it arrived.
struct SuggestionRunRow: Identifiable, Hashable, Sendable {
    var page: SuggestionPage
    /// "English (U.S.) 3/3 · German 0/1", "iPhone 1/1 · Apple Watch 1/4", or
    /// the fields' names; once the run is over, "English (U.S.) 3 · German 1".
    var detail: String
    var arrived: Int
    var total: Int

    var id: SuggestionPage { page }

    var fraction: Double {
        total > 0 ? min(1, Double(arrived) / Double(total)) : 0
    }

    /// "3 of 5", while the run goes on.
    var progressText: String {
        String(localized: "\(arrived) of \(total)")
    }

    /// "5 suggestions", once it's over.
    var countText: String {
        arrived == 1 ? String(localized: "1 suggestion") : String(localized: "\(arrived) suggestions")
    }
}
