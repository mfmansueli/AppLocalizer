//
//  AppStoreConnectJWTTests.swift
//  AppLocalizerTests
//

import CryptoKit
import Foundation
import Testing
@testable import AppLocalizer

@Suite("AppStoreConnectJWT")
struct AppStoreConnectJWTTests {
    private let key = P256.Signing.PrivateKey()
    private let issuedAt = Date(timeIntervalSince1970: 1_800_000_000)

    private func segments() throws -> [Substring] {
        try AppStoreConnectJWT.token(for: TestKeys.credentials(with: key), issuedAt: issuedAt).split(separator: ".")
    }

    private func json(_ segment: Substring) throws -> [String: Any] {
        let data = try #require(TestKeys.decodeSegment(segment))
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test func tokenHasThreeSegments() throws {
        #expect(try segments().count == 3)
    }

    @Test func headerNamesTheAlgorithmAndKey() throws {
        let header = try json(segments()[0])
        #expect(header["alg"] as? String == "ES256")
        #expect(header["kid"] as? String == TestKeys.keyID)
        #expect(header["typ"] as? String == "JWT")
    }

    @Test func claimsCarryIssuerAudienceAndExpiry() throws {
        let claims = try json(segments()[1])
        #expect(claims["iss"] as? String == TestKeys.issuerID)
        #expect(claims["aud"] as? String == "appstoreconnect-v1")
        #expect(claims["iat"] as? Int == 1_800_000_000)
        #expect(claims["exp"] as? Int == 1_800_000_000 + 15 * 60)
    }

    // Apple rejects tokens that live longer than 20 minutes.
    @Test func lifetimeStaysUnderAppleLimit() {
        #expect(AppStoreConnectJWT.lifetime <= 20 * 60)
    }

    @Test func signatureVerifiesWithThePublicKey() throws {
        let parts = try segments()
        let signingInput = Data("\(parts[0]).\(parts[1])".utf8)
        let rawSignature = try #require(TestKeys.decodeSegment(parts[2]))
        let signature = try P256.Signing.ECDSASignature(rawRepresentation: rawSignature)
        #expect(rawSignature.count == 64)
        #expect(key.publicKey.isValidSignature(signature, for: signingInput))
    }

    @Test func unreadableKeyThrowsInvalidPrivateKey() {
        var credentials = TestKeys.credentials()
        credentials.privateKeyPEM = "-----BEGIN PRIVATE KEY-----\nnope\n-----END PRIVATE KEY-----"
        #expect(throws: AppStoreConnectError.invalidPrivateKey) {
            try AppStoreConnectJWT.token(for: credentials, issuedAt: issuedAt)
        }
    }

    @Test func base64URLHasNoPaddingOrURLUnsafeCharacters() {
        // Standard Base64 of these bytes is "+/8=".
        #expect(Data([0xFB, 0xFF]).base64URLEncodedString() == "-_8")
    }
}
