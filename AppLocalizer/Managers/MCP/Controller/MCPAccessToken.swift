//
//  MCPAccessToken.swift
//  AppLocalizer
//

import Foundation

/// The bearer token every request to the MCP server must carry, e.g.
/// `al_mcp_7Q2m9xV4kP8dRr3tYw6Zs1nB5cJ0hL7e`. It lives in the Keychain and
/// changes only when the person regenerates it.
enum MCPAccessToken {
    static let prefix = "al_mcp_"
    static let secretName = "mcp.accessToken"
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

    /// A new random token: the prefix and 32 letters and digits (about 190
    /// bits), from the system's cryptographic random source.
    static func generate() -> String {
        var generator = SystemRandomNumberGenerator()
        let body = (0..<32).map { _ in alphabet[Int(generator.next(upperBound: UInt(alphabet.count)))] }
        return prefix + String(body)
    }

    /// "al_mcp_••••…7e2a": the prefix, dots and the last four characters.
    static func masked(_ token: String) -> String {
        let body = token.dropFirst(prefix.count)
        return prefix + String(repeating: "•", count: max(body.count - 4, 0)) + body.suffix(4)
    }

    /// "al_mcp_…7e2a", for commands shown on screen.
    static func abbreviated(_ token: String) -> String {
        "\(prefix)…\(token.suffix(4))"
    }

    /// Whether an `Authorization` header carries `token`, compared in
    /// constant time so the comparison doesn't leak how much matched.
    static func authorizes(_ header: String?, token: String) -> Bool {
        guard let header, header.lowercased().hasPrefix("bearer ") else { return false }
        let given = Array(header.dropFirst("bearer ".count).trimmingCharacters(in: .whitespaces).utf8)
        let expected = Array(token.utf8)
        guard given.count == expected.count else { return false }
        return zip(given, expected).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}
