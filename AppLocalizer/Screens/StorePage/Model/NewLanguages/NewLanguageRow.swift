//
//  NewLanguageRow.swift
//  AppLocalizer
//

import Foundation

/// One row of "Languages in the app, not on the App Store": a language the
/// app's project has and its App Store page doesn't, how much of it is
/// translated, and whether its page is drafted or already added.
struct NewLanguageRow: Identifiable, Hashable, Sendable {
    let locale: StoreLocale
    /// "Localizable.xcstrings: 412 of 418 strings (98%) · Right to left;
    /// tested in LumenUITests".
    let evidence: String
    /// "Claude Code drafted 6 fields; they wait in its tab for you."
    let drafted: String
    /// Added here and not pushed yet: checked, and it can't be unchecked.
    let isAdded: Bool

    var id: String { locale.code }
}
