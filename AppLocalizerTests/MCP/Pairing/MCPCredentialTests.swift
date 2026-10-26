//
//  MCPCredentialTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("Pairing tokens and codes")
struct MCPCredentialTests {
    private let now = Date(timeIntervalSince1970: 1_792_000_000)

    @Test func tokensAreLongRandomAndPrefixed() {
        let token = MCPAccessToken.generate()
        #expect(token.hasPrefix("al_pair_"))
        #expect(token.count == "al_pair_".count + 32)
        #expect(token.dropFirst(8).allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) })
        #expect(MCPAccessToken.generate() != token)
    }

    @Test func tokensAreReadFromBearerHeaders() {
        #expect(MCPAccessToken.bearer(in: "Bearer al_pair_abc") == "al_pair_abc")
        #expect(MCPAccessToken.bearer(in: "bearer   al_pair_abc ") == "al_pair_abc")
        #expect(MCPAccessToken.bearer(in: "Basic dXNlcjpwYXNz") == nil)
        #expect(MCPAccessToken.bearer(in: "Bearer ") == nil)
        #expect(MCPAccessToken.bearer(in: nil) == nil)
    }

    @Test func tokensMatchOnlyThemselves() {
        #expect(MCPAccessToken.matches("al_pair_abcd", token: "al_pair_abcd"))
        #expect(!MCPAccessToken.matches("al_pair_abce", token: "al_pair_abcd"))
        #expect(!MCPAccessToken.matches("al_pair_abc", token: "al_pair_abcd"))
        #expect(!MCPAccessToken.matches("", token: "al_pair_abcd"))
    }

    @Test func tokensAreShownMaskedOrAbbreviated() {
        #expect(MCPAccessToken.masked("al_pair_ABCDEFGH") == "al_pair_••••EFGH")
        #expect(MCPAccessToken.abbreviated("al_pair_ABCDEFGH") == "al_pair_…EFGH")
    }

    @Test func codesAreSixDigitsForTenMinutes() {
        let code = MCPPairingCode.generate(now: now)
        #expect(code.digits.count == 6)
        #expect(code.digits.allSatisfy { $0.isASCII && $0.isNumber })
        #expect(code.expiresAt == now.addingTimeInterval(600))
        #expect(code.isUsable(at: now.addingTimeInterval(599)))
        #expect(!code.isUsable(at: now.addingTimeInterval(600)))
    }

    @Test func codesMatchWithOrWithoutTheSpace() {
        let code = MCPPairingCode(digits: "482913", expiresAt: now)
        #expect(code.formatted == "482 913")
        #expect(code.matches("482913"))
        #expect(code.matches(" 482 913 "))
        #expect(!code.matches("482914"))
        #expect(!code.matches("48291"))
        #expect(!code.matches("4829130"))
    }

    @Test func codesStopWorkingAfterFiveWrongTries() {
        var code = MCPPairingCode(digits: "482913", expiresAt: now.addingTimeInterval(600))
        code.failedAttempts = 4
        #expect(code.isUsable(at: now))
        code.failedAttempts = 5
        #expect(!code.isUsable(at: now))
    }
}
