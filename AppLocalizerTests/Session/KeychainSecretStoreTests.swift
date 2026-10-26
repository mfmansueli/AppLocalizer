//
//  KeychainSecretStoreTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

// Uses the real login Keychain under a throwaway service name per test.
@Suite("KeychainSecretStore")
struct KeychainSecretStoreTests {
    private let store = KeychainSecretStore(service: "AppLocalizerTests.\(UUID().uuidString)")

    @Test func missingSecretIsNil() throws {
        #expect(try store.secret(named: "translation.anthropic.apiKey") == nil)
    }

    @Test func savedSecretReadsBackAndNilRemovesIt() throws {
        try store.setSecret("sk-test-1", named: "key")
        #expect(try store.secret(named: "key") == "sk-test-1")
        try store.setSecret("sk-test-2", named: "key")
        #expect(try store.secret(named: "key") == "sk-test-2")
        try store.setSecret(nil, named: "key")
        #expect(try store.secret(named: "key") == nil)
    }
}
