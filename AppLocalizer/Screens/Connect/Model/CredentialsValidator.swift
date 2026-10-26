//
//  CredentialsValidator.swift
//  AppLocalizer
//

import CryptoKit
import Foundation

/// Checks the connect form locally before anything is sent to Apple. Only
/// the format is checked here; whether the key is real and not revoked is
/// what `ConnectServices.verify` asks App Store Connect.
enum CredentialsValidator {
    static func issuerIDIssue(_ issuerID: String) -> CredentialsIssue? {
        UUID(uuidString: issuerID.trimmed) == nil ? .invalidIssuerID : nil
    }

    // Apple's key IDs are 10 uppercase letters and digits today; only the
    // character set is enforced so a longer ID wouldn't lock anyone out.
    static func keyIDIssue(_ keyID: String) -> CredentialsIssue? {
        let keyID = keyID.trimmed
        let isAlphanumeric = keyID.unicodeScalars.allSatisfy { $0.isASCII && CharacterSet.alphanumerics.contains($0) }
        return keyID.isEmpty || !isAlphanumeric ? .invalidKeyID : nil
    }

    static func privateKeyIssue(_ pem: String) -> CredentialsIssue? {
        (try? P256.Signing.PrivateKey(pemRepresentation: pem.trimmed)) == nil ? .unreadablePrivateKey : nil
    }

    /// The trimmed credentials, or nil while any field has an issue.
    static func credentials(issuerID: String, keyID: String, privateKeyPEM: String?) -> AppStoreConnectCredentials? {
        guard let privateKeyPEM,
              issuerIDIssue(issuerID) == nil,
              keyIDIssue(keyID) == nil,
              privateKeyIssue(privateKeyPEM) == nil
        else { return nil }
        return AppStoreConnectCredentials(
            issuerID: issuerID.trimmed.lowercased(),
            keyID: keyID.trimmed.uppercased(),
            privateKeyPEM: privateKeyPEM.trimmed
        )
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
