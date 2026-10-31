//
//  StudioSetSummary.swift
//  AppLocalizer
//

import Foundation

/// The Live set / New set card: how it was made, languages, iPad, checks.
struct StudioSetSummary: Hashable, Sendable {
    struct Line: Hashable, Sendable, Identifiable {
        var label: String
        var value: String
        var id: String { label }
    }

    var title: String
    var pill: String
    var pillStyle: PillStyle
    var lines: [Line]
}
