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
    private let services = FakeConnectServices()
    private let key = ImportedPrivateKey(fileName: "AuthKey_2X9R4HXF34.p8", pem: P256.Signing.PrivateKey().pemRepresentation)

    private func model(onConnect: @escaping (AppStoreConnectCredentials) throws -> Void = { _ in }) -> ConnectViewModel {
        ConnectViewModel(services: services, onConnect: onConnect)
    }

    private func filledModel(onConnect: @escaping (AppStoreConnectCredentials) throws -> Void = { _ in }) -> ConnectViewModel {
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

    @Test func typedFieldsShowTheirHints() {
        let vm = model()
        vm.issuerID = "1234"
        vm.keyID = "AB-12"
        #expect(vm.issuerIDIssue == .invalidIssuerID)
        #expect(vm.keyIDIssue == .invalidKeyID)
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

    @Test func importingAnythingElseIsRejected() {
        let vm = model()
        vm.importKey(ImportedPrivateKey(fileName: "notes.p8", pem: "hello"))
        #expect(vm.privateKey == nil)
        #expect(vm.importErrorMessage == CredentialsIssue.unreadablePrivateKey.message)
    }

    @Test func aGoodImportClearsThePreviousError() {
        let vm = model()
        vm.importKey(ImportedPrivateKey(fileName: "notes.p8", pem: "hello"))
        vm.importKey(key)
        #expect(vm.importErrorMessage == nil)
    }

    @Test func importIsPassedThroughTheInitializer() {
        let vm = ConnectViewModel(services: services, privateKey: key) { _ in }
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
        #expect(!vm.canConnect)
    }

    // MARK: - Connecting

    @Test func verifiedKeyIsHandedOver() async {
        var connected: AppStoreConnectCredentials?
        let vm = filledModel { connected = $0 }
        await vm.connect()
        #expect(services.verified.count == 1)
        #expect(connected == services.verified.first)
        #expect(connected?.keyID == "2X9R4HXF34")
        #expect(vm.errorMessage == nil)
        #expect(!vm.isVerifying)
    }

    @Test func rejectedKeyShowsApplesAnswerAndIsNotSaved() async {
        services.verifyError = AppStoreConnectError.unauthorized
        var connected = false
        let vm = filledModel { _ in connected = true }
        await vm.connect()
        #expect(!connected)
        #expect(vm.errorMessage == AppStoreConnectError.unauthorized.errorDescription)
        #expect(!vm.isVerifying)
    }

    @Test func savingFailureIsShown() async {
        let vm = filledModel { _ in throw KeychainError(status: errSecDuplicateItem) }
        await vm.connect()
        #expect(vm.errorMessage == KeychainError(status: errSecDuplicateItem).errorDescription)
    }

    @Test func checkingTheKeyShowsProgressAndBlocksASecondTap() async {
        let vm = filledModel()
        var wasVerifying = false
        var couldConnectMeanwhile = true
        services.whileVerifying = {
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
        #expect(services.verified.isEmpty)
    }

    @Test func retryingClearsThePreviousError() async {
        services.verifyError = AppStoreConnectError.unauthorized
        let vm = filledModel()
        await vm.connect()
        services.verifyError = nil
        await vm.connect()
        #expect(vm.errorMessage == nil)
    }
}
