//
//  KeyAssistantTokens.swift
//  AppLocalizer
//

import Foundation

/// About how many tokens a text is, before it's sent: a quarter of its
/// characters, which is close for English and errs high for most other
/// languages' scripts.
enum KeyAssistantTokens {
    static func estimate(_ text: String) -> Int {
        Int((Double(text.count) / 4).rounded(.up))
    }

    /// "400", "2.1k".
    static func formatted(_ count: Int) -> String {
        guard count >= 1000 else { return count.formatted() }
        return (Double(count) / 1000).formatted(.number.precision(.fractionLength(1))) + "k"
    }
}
