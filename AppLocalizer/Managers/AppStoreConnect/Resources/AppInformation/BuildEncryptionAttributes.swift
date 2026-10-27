//
//  BuildEncryptionAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `builds` attributes Export Compliance reads: the build number and
/// whether it uses non-exempt encryption (nil until answered, or when the
/// Info.plist key answered it).
struct BuildEncryptionAttributes: Decodable, Sendable {
    var version: String?
    var usesNonExemptEncryption: Bool?
}
