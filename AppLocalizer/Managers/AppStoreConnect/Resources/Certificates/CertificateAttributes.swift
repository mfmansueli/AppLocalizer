//
//  CertificateAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `certificates` resource attributes AppLocalizer asks for
/// (`fields[certificates]`): the certificate itself, which names the team
/// it was issued to.
struct CertificateAttributes: Decodable, Sendable {
    /// The certificate, DER encoded, in base64.
    var certificateContent: String?

    /// The team the certificate was issued to, from its subject.
    var teamName: String? {
        certificateContent
            .flatMap { Data(base64Encoded: $0, options: .ignoreUnknownCharacters) }
            .flatMap(CertificateOrganization.name(inDER:))
    }
}
