//
//  LayoutReviews.swift
//  AppLocalizer
//

import Foundation

/// A Reviews slot as laid out: no device and no capture, the reviews
/// under the headline. The counts are what the checks judge.
struct LayoutReviews: Hashable, Sendable {
    /// Reviews from the language's own storefront.
    var own: Int
    /// Reviews from the primary language's storefront, filling in.
    var borrowed: Int
    /// Whether the language's storefront was looked up.
    var isChecked: Bool
    /// The reviews' words and names, for the render key.
    var signature = ""
    /// No review to quote: the slot is laid out like the others, its
    /// device and capture in place of the reviews. Bruma, not on the App
    /// Store yet, had an empty second screenshot in Social Proof, Claude's
    /// pick.
    var showsCapture = false

    /// Quotes the reviews: no device and no capture.
    var showsQuotes: Bool { !showsCapture }
}
