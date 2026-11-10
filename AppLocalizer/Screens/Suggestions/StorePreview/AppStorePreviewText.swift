//
//  AppStorePreviewText.swift
//  AppLocalizer
//

import Foundation

/// A piece of text on the preview, and whether it's a suggestion nobody has
/// accepted yet, which the preview highlights.
struct AppStorePreviewText: Equatable, Sendable {
    var value = ""
    var isSuggested = false
}
