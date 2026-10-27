//
//  MCPAccessToken.swift
//  AppLocalizer
//

import Foundation

/// The bearer token a paired assistant sends with every request, e.g.
/// `al_pair_C7Q2m9xV4kP8dRr3tYw6Zs1nB5cJ0hL7`. Each paired client has its
/// own, in the Keychain, until the person revokes it.
enum MCPAccessToken {
    static let prefix = "al_pair_"
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

    /// A new random token: the prefix and 32 letters and digits (about 190
    /// bits), from the system's cryptographic random source.
    static func generate() -> String {
        var generator = SystemRandomNumberGenerator()
        let body = (0..<32).map { _ in alphabet[Int(generator.next(upperBound: UInt(alphabet.count)))] }
        return prefix + String(body)
    }

    /// "al_pair_••••…7e2a": the prefix, dots and the last four characters.
    static func masked(_ token: String) -> String {
        let body = token.dropFirst(prefix.count)
        return prefix + String(repeating: "•", count: max(body.count - 4, 0)) + body.suffix(4)
    }

    /// "al_pair_…7e2a", for commands shown on screen.
    static func abbreviated(_ token: String) -> String {
        "\(prefix)…\(token.suffix(4))"
    }

    /// The credential in an `Authorization: Bearer …` header.
    static func bearer(in header: String?) -> String? {
        guard let header, header.lowercased().hasPrefix("bearer ") else { return nil }
        let value = header.dropFirst("bearer ".count).trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    /// Whether `given` is `token`, compared in constant time so the
    /// comparison doesn't leak how much matched.
    static func matches(_ given: String, token: String) -> Bool {
        let given = Array(given.utf8)
        let expected = Array(token.utf8)
        guard given.count == expected.count else { return false }
        return zip(given, expected).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}
