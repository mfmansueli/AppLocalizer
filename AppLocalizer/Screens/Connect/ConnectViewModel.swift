//
//  ConnectViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The connect form: Issuer ID, Key ID and the `.p8` key. Each field is
/// checked locally once the person leaves it (`CredentialsValidator`), then
/// "Connect" checks the key with App Store Connect (`KeyChecker`) and only a
/// key that works is handed to `onConnect`, which saves it.
@MainActor
@Observable
final class ConnectViewModel {
    var issuerID = ""
    /// Uppercased as it's typed (`uppercaseKeyID()`).
    var keyID = ""

    private(set) var privateKey: ImportedPrivateKey?
    /// The name of a picked or dropped file that isn't a `.p8` key.
    private(set) var rejectedFileName: String?
    /// Why the last picked or dropped file couldn't even be read.
    private(set) var importErrorMessage: String?
    /// Why the last "Connect" failed (Apple's answer, network, Keychain).
    private(set) var failure: KeyCheckFailure?
    private(set) var isVerifying = false
    /// Fields the person has left at least once; only those show hints.
    private(set) var leftFields: Set<Field> = []

    private let checker: any KeyChecker
    private let onConnect: (AppStoreConnectCredentials, KeyAccessCheck) throws -> Void

    init(
        checker: any KeyChecker,
        privateKey: ImportedPrivateKey? = nil,
        onConnect: @escaping (AppStoreConnectCredentials, KeyAccessCheck) throws -> Void
    ) {
        self.checker = checker
        self.onConnect = onConnect
        if let privateKey { importKey(privateKey) }
    }

    /// A text field of the form, for "validate when it loses focus".
    enum Field: Hashable, Sendable {
        case issuerID
        case keyID
    }

    // An empty field isn't wrong yet, and neither is one still being typed.
    var issuerIDIssue: CredentialsIssue? {
        guard leftFields.contains(.issuerID), !issuerID.isEmpty else { return nil }
        return CredentialsValidator.issuerIDIssue(issuerID)
    }

    var keyIDIssue: CredentialsIssue? {
        guard leftFields.contains(.keyID), !keyID.isEmpty else { return nil }
        return CredentialsValidator.keyIDIssue(keyID)
    }

    var credentials: AppStoreConnectCredentials? {
        CredentialsValidator.credentials(issuerID: issuerID, keyID: keyID, privateKeyPEM: privateKey?.pem)
    }

    var canConnect: Bool { credentials != nil && !isVerifying }

    func leave(_ field: Field) {
        leftFields.insert(field)
    }

    /// Key IDs are capital letters and digits; the view calls this after
    /// each edit, so the field shows the uppercased text while typing.
    func uppercaseKeyID() {
        let uppercased = keyID.uppercased()
        if uppercased != keyID { keyID = uppercased }
    }

    /// A picked or dropped file. Fills in an empty Key ID from the
    /// `AuthKey_<KEYID>.p8` name.
    func importKey(_ key: ImportedPrivateKey) {
        importErrorMessage = nil
        guard CredentialsValidator.privateKeyIssue(key.pem) == nil else {
            privateKey = nil
            rejectedFileName = key.fileName
            return
        }
        privateKey = key
        rejectedFileName = nil
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
        rejectedFileName = nil
        importErrorMessage = nil
    }

    func connect() async {
        guard let credentials, !isVerifying else { return }
        isVerifying = true
        failure = nil
        defer { isVerifying = false }
        do {
            let check = try await checker.check(credentials)
            try onConnect(credentials, check)
        } catch {
            failure = KeyCheckFailure(error)
        }
    }
}
