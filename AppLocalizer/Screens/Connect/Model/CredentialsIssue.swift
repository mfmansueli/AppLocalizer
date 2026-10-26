//
//  CredentialsIssue.swift
//  AppLocalizer
//

import Foundation

/// Why the connect form can't be submitted yet, with the hint shown under
/// the field once the person leaves it.
enum CredentialsIssue: Equatable, Sendable {
    case invalidIssuerID
    case invalidKeyID
    case unreadablePrivateKey

    var message: String {
        switch self {
        case .invalidIssuerID:
            String(localized: "An Issuer ID is a UUID: 8-4-4-4-12 hexadecimal characters. It’s shown above the keys table.")
        case .invalidKeyID:
            String(localized: "A Key ID is 10 capital letters and digits, like 2X9R4HXF34.")
        case .unreadablePrivateKey:
            String(localized: "Choose the AuthKey_….p8 file you downloaded from App Store Connect. Apple lets you download it only once.")
        }
    }
}
