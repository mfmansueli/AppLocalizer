//
//  AppEncryptionDeclarationAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `appEncryptionDeclarations` attributes: the full export compliance
/// answers of a declaration made in App Store Connect. AppLocalizer reads
/// them to start from; creating one needs documents, which it doesn't do.
struct AppEncryptionDeclarationAttributes: Decodable, Sendable {
    var usesEncryption: Bool?
    var exempt: Bool?
    var containsProprietaryCryptography: Bool?
    var containsThirdPartyCryptography: Bool?
    var availableOnFrenchStore: Bool?
    /// ISO 8601; the newest declaration is the one that applies.
    var createdDate: String?
}
