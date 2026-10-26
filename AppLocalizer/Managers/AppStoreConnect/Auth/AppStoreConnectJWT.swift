//
//  AppStoreConnectJWT.swift
//  AppLocalizer
//

import CryptoKit
import Foundation

/// The bearer token every App Store Connect API request carries: a JWT
/// signed with the team key's P-256 private key (ES256), as described in
/// "Generating Tokens for API Requests". Signing is cheap, so the client signs
/// a fresh token per request instead of caching one.
enum AppStoreConnectJWT {
    static let audience = "appstoreconnect-v1"
    /// Apple rejects tokens whose `exp` is more than 20 minutes after `iat`.
    static let lifetime: TimeInterval = 15 * 60

    static func token(for credentials: AppStoreConnectCredentials, issuedAt: Date) throws -> String {
        let key: P256.Signing.PrivateKey
        do {
            key = try P256.Signing.PrivateKey(pemRepresentation: credentials.privateKeyPEM)
        } catch {
            throw AppStoreConnectError.invalidPrivateKey
        }

        let issuedAtSeconds = Int(issuedAt.timeIntervalSince1970)
        let header = Header(kid: credentials.keyID)
        let claims = Claims(
            iss: credentials.issuerID,
            iat: issuedAtSeconds,
            exp: issuedAtSeconds + Int(lifetime),
            aud: audience
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let signingInput = try [encoder.encode(header), encoder.encode(claims)]
            .map { $0.base64URLEncodedString() }
            .joined(separator: ".")
        // JWS wants the raw 64-byte r‖s signature, not DER.
        let signature = try key.signature(for: Data(signingInput.utf8))
        return signingInput + "." + signature.rawRepresentation.base64URLEncodedString()
    }

    private struct Header: Encodable {
        var alg = "ES256"
        var kid: String
        var typ = "JWT"
    }

    /// The registered JWT claim names Apple requires.
    private struct Claims: Encodable {
        var iss: String
        var iat: Int
        var exp: Int
        var aud: String
    }
}
