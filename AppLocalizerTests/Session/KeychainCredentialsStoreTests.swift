//
//  KeychainCredentialsStoreTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

// Uses the real login Keychain, under a throwaway service name per test so
// it never touches the app's own item, and deletes what it wrote.
@Suite("KeychainCredentialsStore")
struct KeychainCredentialsStoreTests {
    private let store = KeychainCredentialsStore(service: "AppLocalizerTests.\(UUID().uuidString)")

    @Test func loadIsNilBeforeAnythingIsSaved() throws {
        #expect(try store.load() == nil)
    }

    @Test func savedCredentialsLoadBack() throws {
        defer { try? store.delete() }
        let credentials = TestKeys.credentials()
        try store.save(credentials)
        #expect(try store.load() == credentials)
    }

    @Test func savingAgainReplacesTheKey() throws {
        defer { try? store.delete() }
        try store.save(TestKeys.credentials())
        let replacement = TestKeys.credentials()
        try store.save(replacement)
        #expect(try store.load() == replacement)
    }

    @Test func deleteRemovesTheKey() throws {
        try store.save(TestKeys.credentials())
        try store.delete()
        #expect(try store.load() == nil)
    }

    @Test func deletingNothingSucceeds() throws {
        try store.delete()
    }
}
