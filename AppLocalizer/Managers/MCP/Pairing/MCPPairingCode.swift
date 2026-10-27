//
//  MCPPairingCode.swift
//  AppLocalizer
//

import Foundation

/// The six-digit code the pairing sheet shows for clients that ask for a
/// code instead of a token. It works once, for ten minutes, and only while
/// that pairing is waiting; a few wrong guesses void it.
struct MCPPairingCode: Hashable, Sendable {
    static let lifetime: TimeInterval = 10 * 60
    static let allowedFailures = 5

    /// Six digits, e.g. "482913".
    var digits: String
    var expiresAt: Date
    var failedAttempts = 0

    /// A random code from the system's cryptographic source.
    static func generate(now: Date) -> MCPPairingCode {
        var generator = SystemRandomNumberGenerator()
        let digits = (0..<6).map { _ in String(generator.next(upperBound: UInt8(10))) }.joined()
        return MCPPairingCode(digits: digits, expiresAt: now.addingTimeInterval(lifetime))
    }

    /// "482 913", as the sheet shows it.
    var formatted: String {
        "\(digits.prefix(3)) \(digits.suffix(3))"
    }

    func isUsable(at date: Date) -> Bool {
        date < expiresAt && failedAttempts < Self.allowedFailures
    }

    /// Whether `given` is this code; spaces are ignored and the comparison
    /// takes the same time however much matches.
    func matches(_ given: String) -> Bool {
        let cleaned = Array(given.filter { !$0.isWhitespace }.utf8)
        let expected = Array(digits.utf8)
        guard cleaned.count == expected.count else { return false }
        return zip(cleaned, expected).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}
