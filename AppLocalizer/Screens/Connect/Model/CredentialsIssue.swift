//
//  CredentialsIssue.swift
//  AppLocalizer
//

import Foundation

/// Why the connect form can't be submitted yet, with the hint shown under
/// the field.
enum CredentialsIssue: Equatable, Sendable {
    case invalidIssuerID
    case invalidKeyID
    case unreadablePrivateKey

    var message: String {
        switch self {
        case .invalidIssuerID:
            String(localized: "The Issuer ID is a UUID, like 57246542-96fe-1a63-e053-0824d011072a.")
        case .invalidKeyID:
            String(localized: "The Key ID is made of letters and digits, like 2X9R4HXF34.")
        case .unreadablePrivateKey:
            String(localized: "That file isn't an App Store Connect private key. Choose the AuthKey_….p8 file.")
        }
    }
}
