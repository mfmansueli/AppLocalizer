//
//  AppStoreConnectClient+Team.swift
//  AppLocalizer
//

import Foundation

// The team's name. App Store Connect has no endpoint that names the team a
// key belongs to, but every certificate it issues does: the subject's
// organization is the team.
extension AppStoreConnectClient {
    /// The team's name from its certificates (`GET /v1/certificates`), or
    /// nil when it has none. Throws `.forbidden` when the key's role can't
    /// read Certificates, Identifiers & Profiles.
    func teamName() async throws -> String? {
        let page: CertificatesPage = try await get(url("/v1/certificates", query: [
            URLQueryItem(name: "fields[certificates]", value: "certificateContent"),
            URLQueryItem(name: "limit", value: "20"),
        ]))
        return page.data.lazy.compactMap { $0.attributes?.teamName }.first
    }

    /// Just the certificates; one without attributes is skipped, not an
    /// unexpected payload.
    private struct CertificatesPage: Decodable {
        var data: [CertificatesPageCertificate]
    }

    private struct CertificatesPageCertificate: Decodable {
        var attributes: CertificateAttributes?
    }
}
