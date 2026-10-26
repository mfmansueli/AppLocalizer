//
//  ConnectViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The connect form: Issuer ID, Key ID and the `.p8` key. Fields are checked
/// locally as they're typed (`CredentialsValidator`), then "Connect" makes
/// one signed request to Apple (`ConnectServices.verify`) and only a key that
/// works is handed to `onConnect`, which saves it.
@MainActor
@Observable
final class ConnectViewModel {
    var issuerID = ""
    var keyID = ""
    private(set) var privateKey: ImportedPrivateKey?
    /// Why the last picked/dropped file was rejected.
    private(set) var importErrorMessage: String?
    /// Why the last "Connect" failed (Apple's answer, network, Keychain).
    private(set) var errorMessage: String?
    private(set) var isVerifying = false

    private let services: any ConnectServices
    private let onConnect: (AppStoreConnectCredentials) throws -> Void

    init(
        services: any ConnectServices,
        privateKey: ImportedPrivateKey? = nil,
        onConnect: @escaping (AppStoreConnectCredentials) throws -> Void
    ) {
        self.services = services
        self.onConnect = onConnect
        if let privateKey { importKey(privateKey) }
    }

    // Hints only show once something was typed: an empty form isn't wrong yet.
    var issuerIDIssue: CredentialsIssue? {
        issuerID.isEmpty ? nil : CredentialsValidator.issuerIDIssue(issuerID)
    }

    var keyIDIssue: CredentialsIssue? {
        keyID.isEmpty ? nil : CredentialsValidator.keyIDIssue(keyID)
    }

    var credentials: AppStoreConnectCredentials? {
        CredentialsValidator.credentials(issuerID: issuerID, keyID: keyID, privateKeyPEM: privateKey?.pem)
    }

    var canConnect: Bool { credentials != nil && !isVerifying }

    /// A picked or dropped file. Fills in an empty Key ID from the
    /// `AuthKey_<KEYID>.p8` name.
    func importKey(_ key: ImportedPrivateKey) {
        if let issue = CredentialsValidator.privateKeyIssue(key.pem) {
            importErrorMessage = issue.message
            return
        }
        privateKey = key
        importErrorMessage = nil
        if keyID.trimmingCharacters(in: .whitespaces).isEmpty, let fromName = KeyFileName.keyID(from: key.fileName) {
            keyID = fromName
        }
    }

    /// The file couldn't even be read (permissions, not UTF-8, …).
    func importFailed(_ error: any Error) {
        importErrorMessage = error.localizedDescription
    }

    func removeKey() {
        privateKey = nil
        importErrorMessage = nil
    }

    func connect() async {
        guard let credentials, !isVerifying else { return }
        isVerifying = true
        errorMessage = nil
        defer { isVerifying = false }
        do {
            try await services.verify(credentials)
            try onConnect(credentials)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
