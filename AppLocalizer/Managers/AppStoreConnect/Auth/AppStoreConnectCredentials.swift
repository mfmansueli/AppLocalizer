//
//  AppStoreConnectCredentials.swift
//  AppLocalizer
//

import Foundation

/// A team API key from App Store Connect (Users and Access → Integrations →
/// App Store Connect API). The private key is the `AuthKey_<KEYID>.p8` file
/// Apple lets you download once; it never leaves this Mac — requests are
/// signed with it locally (`AppStoreConnectJWT`).
struct AppStoreConnectCredentials: Codable, Hashable, Sendable {
    /// The team's issuer ID, a UUID shown above the keys list.
    var issuerID: String
    /// The key's 10-character ID, e.g. `2X9R4HXF34`.
    var keyID: String
    /// The `.p8` file's contents: a PKCS#8 PEM P-256 private key.
    var privateKeyPEM: String
    /// What the person calls this team. Nil shows the name App Store Connect
    /// gives it (`AppSession.teamNames`), or a default.
    var teamName: String?
}
