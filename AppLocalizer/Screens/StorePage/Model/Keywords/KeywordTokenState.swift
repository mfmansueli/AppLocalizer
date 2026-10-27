//
//  KeywordTokenState.swift
//  AppLocalizer
//

import Foundation

/// How a keyword token is drawn: plain, yellow when it repeats an earlier
/// one, struck through when the name or subtitle already covers it.
enum KeywordTokenState: Hashable, Sendable {
    /// Earns its bytes.
    case useful
    case duplicate
    /// The App Store already indexes the name and subtitle, so these bytes
    /// are wasted.
    case inNameOrSubtitle
}
