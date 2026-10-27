//
//  ConnectViewModelTests.swift
//  AppLocalizerTests
//

import CryptoKit
import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("ConnectViewModel")
struct ConnectViewModelTests {
    private let checker = FakeKeyChecker()
    private let key = ImportedPrivateKey(fileName: "AuthKey_2X9R4HXF34.p8", pem: P256.Signing.PrivateKey().pemRepresentation)

    private func model(
        onConnect: @escaping (AppStoreConnectCredentials, KeyAccessCheck) throws -> Void = { _, _ in }
    ) -> ConnectViewModel {
        ConnectViewModel(checker: checker, onConnect: onConnect)
    }

    private func filledModel(
        onConnect: @escaping (AppStoreConnectCredentials, KeyAccessCheck) throws -> Void = { _, _ in }
    ) -> ConnectViewModel {
        let vm = model(onConnect: onConnect)
        vm.issuerID = TestKeys.issuerID
        vm.importKey(key)
        return vm
    }

    // MARK: - Form

    @Test func emptyFormCantConnectAndShowsNoHints() {
        let vm = model()
        #expect(!vm.canConnect)
        #expect(vm.issuerIDIssue == nil)
        #expect(vm.keyIDIssue == nil)
    }

    @Test func hintsWaitUntilTheFieldIsLeft() {
        let vm = model()
        vm.issuerID = "1234"
        vm.keyID = "AB-12"
        #expect(vm.issuerIDIssue == nil)
        #expect(vm.keyIDIssue == nil)

        vm.leave(.issuerID)
        vm.leave(.keyID)
        #expect(vm.issuerIDIssue == .invalidIssuerID)
        #expect(vm.keyIDIssue == .invalidKeyID)
    }

    @Test func aLeftFieldsHintFollowsTheFix() {
        let vm = model()
        vm.issuerID = "1234"
        vm.leave(.issuerID)
        vm.issuerID = TestKeys.issuerID
        #expect(vm.issuerIDIssue == nil)
    }

    @Test func leavingAnEmptyFieldShowsNoHint() {
        let vm = model()
        vm.leave(.keyID)
        #expect(vm.keyIDIssue == nil)
    }

    @Test func keyIDIsUppercased() {
        let vm = model()
        vm.keyID = "2x9r4hxf34"
        vm.uppercaseKeyID()
        #expect(vm.keyID == "2X9R4HXF34")
    }

    @Test func completeFormCanConnect() {
        #expect(filledModel().canConnect)
    }

    @Test func formWithoutAKeyCantConnect() {
        let vm = model()
        vm.issuerID = TestKeys.issuerID
        vm.keyID = TestKeys.keyID
        #expect(!vm.canConnect)
    }

    // MARK: - Importing the key

    @Test func importingFillsAnEmptyKeyIDFromTheFileName() {
        let vm = model()
        vm.importKey(key)
        #expect(vm.privateKey == key)
        #expect(vm.keyID == "2X9R4HXF34")
    }

    @Test func importingKeepsATypedKeyID() {
        let vm = model()
        vm.keyID = "ZZZZZ99999"
        vm.importKey(key)
        #expect(vm.keyID == "ZZZZZ99999")
    }

    @Test func importingAnythingElseShowsTheFileAsRejected() {
        let vm = model()
        vm.importKey(ImportedPrivateKey(fileName: "notes.txt", pem: "hello"))
        #expect(vm.privateKey == nil)
        #expect(vm.rejectedFileName == "notes.txt")
        #expect(!vm.canConnect)
    }

    @Test func aWrongFileReplacesAnImportedKey() {
        let vm = filledModel()
        vm.importKey(ImportedPrivateKey(fileName: "notes.txt", pem: "hello"))
        #expect(vm.privateKey == nil)
        #expect(vm.rejectedFileName == "notes.txt")
    }

    @Test func aGoodImportClearsTheRejectedFile() {
        let vm = model()
        vm.importKey(ImportedPrivateKey(fileName: "notes.txt", pem: "hello"))
        vm.importKey(key)
        #expect(vm.rejectedFileName == nil)
        #expect(vm.privateKey == key)
    }

    @Test func importIsPassedThroughTheInitializer() {
        let vm = ConnectViewModel(checker: checker, privateKey: key) { _, _ in }
        #expect(vm.privateKey == key)
        #expect(vm.keyID == "2X9R4HXF34")
    }

    @Test func unreadableFileShowsItsError() {
        let vm = model()
        vm.importFailed(CocoaError(.fileReadNoPermission))
        #expect(vm.importErrorMessage != nil)
    }

    @Test func removingTheKeyBlocksConnecting() {
        let vm = filledModel()
        vm.removeKey()
        #expect(vm.privateKey == nil)
        #expect(vm.rejectedFileName == nil)
        #expect(!vm.canConnect)
    }

    // MARK: - Connecting

    @Test func checkedKeyIsHandedOverWithWhatTheCheckFound() async {
        var connected: (AppStoreConnectCredentials, KeyAccessCheck)?
        let vm = filledModel { connected = ($0, $1) }
        await vm.connect()
        #expect(checker.checked.count == 1)
        #expect(connected?.0 == checker.checked.first)
        #expect(connected?.0.keyID == "2X9R4HXF34")
        #expect(connected?.1 == checker.result)
        #expect(vm.failure == nil)
        #expect(!vm.isVerifying)
    }

    @Test(arguments: [
        (AppStoreConnectError.unauthorized as any Error, KeyCheckFailure.rejected),
        (AppStoreConnectError.forbidden(detail: nil), .roleTooLow),
        (URLError(.notConnectedToInternet), .offline),
    ])
    func failedCheckShowsWhyAndIsNotSaved(error: any Error, failure: KeyCheckFailure) async {
        checker.error = error
        var connected = false
        let vm = filledModel { _, _ in connected = true }
        await vm.connect()
        #expect(!connected)
        #expect(vm.failure == failure)
        #expect(!vm.isVerifying)
    }

    @Test func savingFailureIsShown() async {
        let vm = filledModel { _, _ in throw KeychainError(status: errSecDuplicateItem) }
        await vm.connect()
        #expect(vm.failure == .other(KeychainError(status: errSecDuplicateItem).errorDescription ?? ""))
    }

    @Test func checkingTheKeyShowsProgressAndBlocksASecondClick() async {
        let vm = filledModel()
        var wasVerifying = false
        var couldConnectMeanwhile = true
        checker.whileChecking = {
            wasVerifying = vm.isVerifying
            couldConnectMeanwhile = vm.canConnect
        }
        await vm.connect()
        #expect(wasVerifying)
        #expect(!couldConnectMeanwhile)
    }

    @Test func incompleteFormDoesNothing() async {
        let vm = model()
        await vm.connect()
        #expect(checker.checked.isEmpty)
    }

    @Test func retryingClearsThePreviousFailure() async {
        checker.error = URLError(.notConnectedToInternet)
        let vm = filledModel()
        await vm.connect()
        checker.error = nil
        await vm.connect()
        #expect(vm.failure == nil)
    }
}
