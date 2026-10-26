//
//  KeywordToken.swift
//  AppLocalizer
//

import Foundation

/// One comma-separated keyword, trimmed.
struct KeywordToken: Identifiable, Hashable, Sendable {
    /// Position among the tokens, for `KeywordAnalysis.removingToken(at:)`.
    let index: Int
    let text: String
    let state: KeywordTokenState

    var id: Int { index }

    /// UTF-8 bytes the token costs, without its comma.
    var byteCount: Int { ListingTextMeasure.utf8Bytes(in: text) }

    /// "stimmung, duplicate" or "tagebuch, already in the name or subtitle".
    var accessibilityLabel: String {
        switch state {
        case .useful: text
        case .duplicate: String(localized: "\(text), duplicate")
        case .inNameOrSubtitle: String(localized: "\(text), already in the name or subtitle")
        }
    }
}
