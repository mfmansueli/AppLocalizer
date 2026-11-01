//
//  CertificateOrganization.swift
//  AppLocalizer
//

import Foundation
import Security

/// Reads the organization (O) out of a certificate's subject. Apple's
/// development and distribution certificates put the team's name there:
/// "CN=Apple Distribution: Northpier Studio (A1B2C3D4E5), OU=A1B2C3D4E5,
/// O=Northpier Studio".
enum CertificateOrganization {
    /// The subject's organization, or nil when the data isn't a certificate
    /// or its subject has none.
    static func name(inDER data: Data) -> String? {
        guard let certificate = SecCertificateCreateWithData(nil, data as CFData),
              let values = SecCertificateCopyValues(certificate, [kSecOIDX509V1SubjectName] as CFArray, nil) as? [String: Any],
              let subject = values[kSecOIDX509V1SubjectName as String] as? [String: Any],
              let fields = subject[kSecPropertyKeyValue as String] as? [[String: Any]]
        else { return nil }
        let organization = fields.first { $0[kSecPropertyKeyLabel as String] as? String == kSecOIDOrganizationName as String }
        let name = (organization?[kSecPropertyKeyValue as String] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return name?.isEmpty == false ? name : nil
    }
}
