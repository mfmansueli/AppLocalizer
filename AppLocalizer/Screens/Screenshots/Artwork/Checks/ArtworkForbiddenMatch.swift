//
//  ArtworkForbiddenMatch.swift
//  AppLocalizer
//

import Foundation

/// Something in a text that Apple doesn't allow on the header or search
/// image: its kind and the words that are it, e.g. price and "$4.99".
struct ArtworkForbiddenMatch: Hashable, Sendable {
    var kind: ArtworkCheckKind
    var snippet: String

    /// The same finding however it's spaced or cased, so the text layer
    /// and the reading of the render count once.
    var key: String {
        "\(kind.rawValue):" + snippet.lowercased().filter { !$0.isWhitespace && !$0.isPunctuation }
    }
}
