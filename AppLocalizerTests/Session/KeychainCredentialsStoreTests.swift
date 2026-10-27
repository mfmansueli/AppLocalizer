//
//  KeychainCredentialsStoreTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

// Uses the real login Keychain, under a throwaway service name per test so
// it never touches the app's own items, and deletes what it wrote.
@Suite("KeychainCredentialsStore")
struct KeychainCredentialsStoreTests {
    private let service = "AppLocalizerTests.\(UUID().uuidString)"
    private var store: KeychainCredentialsStore { KeychainCredentialsStore(service: service) }

    private func cleanUp() {
        for keyID in [TestKeys.keyID, "Q7MZ3K8PLA"] {
            try? store.delete(keyID: keyID)
        }
        try? KeychainItems(service: service, label: "").delete(KeychainCredentialsStore.legacyAccount)
    }

    @Test func nothingIsSavedAtFirst() throws {
        #expect(try store.loadAll().isEmpty)
    }

    @Test func savedKeysLoadBackOldestFirst() throws {
        defer { cleanUp() }
        let first = TestKeys.credentials(teamName: "Northpier Studio")
        let second = TestKeys.credentials(keyID: "Q7MZ3K8PLA")
        try store.save(first)
        try store.save(second)
        let loaded = try store.loadAll()
        #expect(Set(loaded) == [first, second])
        #expect(loaded.count == 2)
    }

    @Test func savingTheSameKeyIDReplacesIt() throws {
        defer { cleanUp() }
        try store.save(TestKeys.credentials())
        let replacement = TestKeys.credentials(teamName: "Renamed")
        try store.save(replacement)
        #expect(try store.loadAll() == [replacement])
    }

    @Test func deleteRemovesOnlyThatKey() throws {
        defer { cleanUp() }
        let kept = TestKeys.credentials(keyID: "Q7MZ3K8PLA")
        try store.save(TestKeys.credentials())
        try store.save(kept)
        try store.delete(keyID: TestKeys.keyID)
        #expect(try store.loadAll() == [kept])
    }

    @Test func deletingNothingSucceeds() throws {
        try store.delete(keyID: "NOTSAVED00")
    }

    @Test func theSingleKeyOfOlderBuildsMovesToItsKeyID() throws {
        defer { cleanUp() }
        let legacy = TestKeys.credentials()
        let items = KeychainItems(service: service, label: "")
        try items.set(JSONEncoder().encode(legacy), for: KeychainCredentialsStore.legacyAccount)

        #expect(try store.loadAll() == [legacy])
        #expect(try items.data(for: KeychainCredentialsStore.legacyAccount) == nil)
        #expect(try items.accounts() == [legacy.keyID])
    }
}
