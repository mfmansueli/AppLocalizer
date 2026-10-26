//
//  TestKeys.swift
//  AppLocalizerTests
//

import CryptoKit
import Foundation
@testable import AppLocalizer

/// Throwaway P-256 keys in the `.p8` format (PKCS#8 PEM), so tests can sign
/// and verify tokens without a real App Store Connect key.
enum TestKeys {
    static let issuerID = "57246542-96fe-1a63-e053-0824d011072a"
    static let keyID = "2X9R4HXF34"

    static func credentials(with key: P256.Signing.PrivateKey = P256.Signing.PrivateKey()) -> AppStoreConnectCredentials {
        AppStoreConnectCredentials(issuerID: issuerID, keyID: keyID, privateKeyPEM: key.pemRepresentation)
    }

    /// Decodes one Base64URL JWT segment (no padding).
    static func decodeSegment(_ segment: Substring) -> Data? {
        var base64 = segment.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return Data(base64Encoded: base64)
    }
}
