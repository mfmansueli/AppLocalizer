//
//  CaptionSuggestion.swift
//  AppLocalizer
//

import Foundation

/// "Suggest a Shorter Version": a shorter headline from the translation
/// provider, measured with the template before it's offered.
struct CaptionSuggestion: Hashable, Sendable {
    var key: LocaleSlot
    var headline: String
    /// "Apple Translation".
    var providerTitle: String
    var fit: CaptionFit
}
