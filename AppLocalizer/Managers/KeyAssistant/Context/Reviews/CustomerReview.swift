//
//  CustomerReview.swift
//  AppLocalizer
//

import Foundation

/// An App Store review, as a request with the key may include it: the
/// stars, the title and what was written.
struct CustomerReview: Hashable, Sendable {
    var rating: Int
    var title: String
    var body: String

    /// "★★★★★ Finally a calm journal: I write every night…".
    var promptLine: String {
        let text = [title, body].filter { !$0.isEmpty }.joined(separator: ": ")
        return String(repeating: "★", count: max(0, min(rating, 5))) + " " + text.replacingOccurrences(of: "\n", with: " ")
    }
}
