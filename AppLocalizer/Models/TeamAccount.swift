//
//  TeamAccount.swift
//  AppLocalizer
//

import Foundation

/// A saved API key as the account switcher shows it: the team's name, what
/// the key can do, and its key ID.
struct TeamAccount: Identifiable, Hashable, Sendable {
    /// The key ID, unique per saved key.
    var id: String
    /// The team's name: what the person typed, else the name on the team's
    /// certificates in App Store Connect, else a default.
    var name: String
    /// e.g. "Admin" or "App Manager", or what the role check found.
    var role: String

    var keyID: String { id }

    /// Up to two letters for the account tile ("Northpier Studio" → "NS").
    var initials: String {
        let words = name.split(whereSeparator: { $0.isWhitespace || $0 == "-" })
        let letters = words.prefix(2).compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}
