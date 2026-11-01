//
//  AppSessionTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("AppSession")
struct AppSessionTests {
    private let northpier = TestKeys.credentials(keyID: "2X9R4HXF34", teamName: "Northpier Studio")
    private let brightline = TestKeys.credentials(keyID: "Q7MZ3K8PLA", teamName: "Brightline Apps")
    private let check = KeyAccessCheck(appCount: 6, milliseconds: 182, salesAccess: .readable, date: Date(timeIntervalSince1970: 0))

    private func defaults() -> UserDefaults {
        let name = "AppSessionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    // MARK: - Launch

    @Test func startsWithTheOldestSavedKey() {
        let session = AppSession(store: FakeCredentialsStore(stored: [northpier, brightline]))
        #expect(session.credentials == northpier)
        #expect(session.accounts.map(\.name) == ["Northpier Studio", "Brightline Apps"])
        #expect(session.loadErrorMessage == nil)
    }

    @Test func startsDisconnectedWithoutASavedKey() {
        let session = AppSession(store: FakeCredentialsStore())
        #expect(session.credentials == nil)
        #expect(session.account == nil)
        #expect(session.accounts.isEmpty)
    }

    @Test func unreadableKeychainIsReportedNotFatal() {
        let store = FakeCredentialsStore()
        store.loadError = KeychainError(status: errSecInteractionNotAllowed)
        let session = AppSession(store: store)
        #expect(session.credentials == nil)
        #expect(session.loadErrorMessage != nil)
    }

    @Test func remembersTheKeyInUseAndItsChecks() {
        let defaults = defaults()
        let store = FakeCredentialsStore(stored: [northpier, brightline])
        let first = AppSession(store: store, defaults: defaults)
        first.select(keyID: brightline.keyID)
        first.record(check, for: brightline.keyID)

        let relaunched = AppSession(store: store, defaults: defaults)
        #expect(relaunched.credentials == brightline)
        #expect(relaunched.checks[brightline.keyID] == check)
    }

    @Test func forgetsARememberedKeyThatIsGone() {
        let defaults = defaults()
        defaults.set("GONE000000", forKey: "currentKeyID")
        let session = AppSession(store: FakeCredentialsStore(stored: [northpier]), defaults: defaults)
        #expect(session.currentKeyID == northpier.keyID)
    }

    @Test func unnamedKeysGetADefaultName() {
        let session = AppSession(store: FakeCredentialsStore(stored: [TestKeys.credentials()]))
        #expect(session.account?.name == "App Store Connect team")
        #expect(session.account?.keyID == TestKeys.keyID)
    }

    // MARK: - The team's name from App Store Connect

    @Test func anUnnamedKeyShowsTheTeamsNameFromAppStoreConnect() {
        let unnamed = TestKeys.credentials()
        let store = FakeCredentialsStore(stored: [unnamed])
        let session = AppSession(store: store)
        session.recordTeamName(" Lima Apps ", for: unnamed.keyID)
        #expect(session.account?.name == "Lima Apps")
        #expect(session.teamNames == [unnamed.keyID: "Lima Apps"])
        // It isn't the person's name for the key.
        #expect(store.stored.first?.teamName == nil)
    }

    @Test func thePersonsNameForAKeyWins() throws {
        let session = AppSession(store: FakeCredentialsStore(stored: [northpier]))
        session.recordTeamName("Northpier Studio Ltd", for: northpier.keyID)
        #expect(session.account?.name == "Northpier Studio")
        try session.rename(keyID: northpier.keyID, to: "")
        #expect(session.account?.name == "Northpier Studio Ltd")
    }

    @Test func onlySavedKeysAndRealNamesAreRecorded() {
        let unnamed = TestKeys.credentials()
        let session = AppSession(store: FakeCredentialsStore(stored: [unnamed]))
        session.recordTeamName("Lima Apps", for: "NOTSAVED00")
        session.recordTeamName("  ", for: unnamed.keyID)
        #expect(session.teamNames.isEmpty)
        #expect(session.account?.name == "App Store Connect team")
    }

    @Test func theTeamsNameIsRememberedAndForgottenWithItsKey() throws {
        let defaults = defaults()
        let unnamed = TestKeys.credentials()
        let store = FakeCredentialsStore(stored: [unnamed, brightline])
        AppSession(store: store, defaults: defaults).recordTeamName("Lima Apps", for: unnamed.keyID)

        let relaunched = AppSession(store: store, defaults: defaults)
        #expect(relaunched.account?.name == "Lima Apps")
        try relaunched.remove(keyID: unnamed.keyID)
        #expect(relaunched.teamNames.isEmpty)
        #expect(AppSession(store: store, defaults: defaults).teamNames.isEmpty)
    }

    // MARK: - Connecting

    @Test func connectSavesSwitchesAndStartsTheFirstSync() throws {
        let store = FakeCredentialsStore(stored: [northpier])
        let session = AppSession(store: store)
        session.isAddingKey = true
        try session.connect(brightline, check: check)
        #expect(store.stored == [northpier, brightline])
        #expect(session.credentials == brightline)
        #expect(session.checks[brightline.keyID] == check)
        #expect(session.firstSyncKeyID == brightline.keyID)
        #expect(!session.isAddingKey)

        session.finishFirstSync()
        #expect(session.firstSyncKeyID == nil)
    }

    @Test func reconnectingAKeyReplacesItAndKeepsItsName() throws {
        let store = FakeCredentialsStore(stored: [northpier])
        let session = AppSession(store: store)
        let renewed = TestKeys.credentials(keyID: northpier.keyID)
        try session.connect(renewed)
        #expect(session.keys.count == 1)
        #expect(session.credentials?.privateKeyPEM == renewed.privateKeyPEM)
        #expect(session.credentials?.teamName == "Northpier Studio")
    }

    @Test func connectStaysAsItWasWhenSavingFails() {
        let store = FakeCredentialsStore()
        store.saveError = KeychainError(status: errSecDuplicateItem)
        let session = AppSession(store: store)
        #expect(throws: KeychainError(status: errSecDuplicateItem)) {
            try session.connect(northpier)
        }
        #expect(session.credentials == nil)
        #expect(session.firstSyncKeyID == nil)
    }

    @Test func connectingClearsTheLaunchError() throws {
        let store = FakeCredentialsStore()
        store.loadError = KeychainError(status: errSecInteractionNotAllowed)
        let session = AppSession(store: store)
        try session.connect(northpier)
        #expect(session.loadErrorMessage == nil)
    }

    // MARK: - Switching, renaming, removing

    @Test func selectSwitchesOnlyToSavedKeys() {
        let session = AppSession(store: FakeCredentialsStore(stored: [northpier, brightline]))
        session.select(keyID: brightline.keyID)
        #expect(session.credentials == brightline)
        session.select(keyID: "NOTSAVED00")
        #expect(session.credentials == brightline)
    }

    @Test func renamingSavesTheNameAndEmptyGoesBackToTheDefault() throws {
        let store = FakeCredentialsStore(stored: [northpier])
        let session = AppSession(store: store)
        try session.rename(keyID: northpier.keyID, to: "  Northpier Labs ")
        #expect(session.account?.name == "Northpier Labs")
        #expect(store.stored.first?.teamName == "Northpier Labs")
        try session.rename(keyID: northpier.keyID, to: " ")
        #expect(session.account?.name == "App Store Connect team")
    }

    @Test func removingTheKeyInUseSwitchesToTheNextOne() throws {
        let store = FakeCredentialsStore(stored: [northpier, brightline])
        let session = AppSession(store: store)
        session.record(check, for: northpier.keyID)
        try session.remove(keyID: northpier.keyID)
        #expect(store.deletedKeyIDs == [northpier.keyID])
        #expect(session.credentials == brightline)
        #expect(session.checks[northpier.keyID] == nil)
    }

    @Test func removingAnotherKeyKeepsTheOneInUse() throws {
        let session = AppSession(store: FakeCredentialsStore(stored: [northpier, brightline]))
        try session.remove(keyID: brightline.keyID)
        #expect(session.credentials == northpier)
        #expect(session.keys == [northpier])
    }

    @Test func removingTheLastKeyGoesBackToConnect() throws {
        let session = AppSession(store: FakeCredentialsStore(stored: [northpier]))
        try session.remove(keyID: northpier.keyID)
        #expect(session.credentials == nil)
        #expect(session.currentKeyID == nil)
    }

    @Test func removingKeepsTheKeyWhenDeletingFails() {
        let store = FakeCredentialsStore(stored: [northpier])
        store.deleteError = KeychainError(status: errSecAuthFailed)
        let session = AppSession(store: store)
        #expect(throws: KeychainError.self) { try session.remove(keyID: northpier.keyID) }
        #expect(session.credentials == northpier)
    }
}
