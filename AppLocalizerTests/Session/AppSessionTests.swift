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
    private let credentials = TestKeys.credentials()

    @Test func startsWithTheSavedKey() {
        let session = AppSession(store: FakeCredentialsStore(stored: credentials))
        #expect(session.credentials == credentials)
        #expect(session.loadErrorMessage == nil)
    }

    @Test func startsDisconnectedWithoutASavedKey() {
        let session = AppSession(store: FakeCredentialsStore())
        #expect(session.credentials == nil)
        #expect(session.loadErrorMessage == nil)
    }

    @Test func unreadableKeychainItemIsReportedNotFatal() {
        let store = FakeCredentialsStore()
        store.loadError = KeychainError(status: errSecInteractionNotAllowed)
        let session = AppSession(store: store)
        #expect(session.credentials == nil)
        #expect(session.loadErrorMessage != nil)
    }

    @Test func connectSavesAndConnects() throws {
        let store = FakeCredentialsStore()
        let session = AppSession(store: store)
        try session.connect(credentials)
        #expect(store.stored == credentials)
        #expect(session.credentials == credentials)
    }

    @Test func connectStaysDisconnectedWhenSavingFails() {
        let store = FakeCredentialsStore()
        store.saveError = KeychainError(status: errSecDuplicateItem)
        let session = AppSession(store: store)
        #expect(throws: KeychainError(status: errSecDuplicateItem)) {
            try session.connect(credentials)
        }
        #expect(session.credentials == nil)
    }

    @Test func connectingClearsTheLaunchError() throws {
        let store = FakeCredentialsStore()
        store.loadError = KeychainError(status: errSecInteractionNotAllowed)
        let session = AppSession(store: store)
        try session.connect(credentials)
        #expect(session.loadErrorMessage == nil)
    }

    @Test func disconnectForgetsTheKey() throws {
        let store = FakeCredentialsStore(stored: credentials)
        let session = AppSession(store: store)
        try session.disconnect()
        #expect(store.deletes == 1)
        #expect(store.stored == nil)
        #expect(session.credentials == nil)
    }

    @Test func disconnectKeepsTheKeyWhenDeletingFails() {
        let store = FakeCredentialsStore(stored: credentials)
        store.deleteError = KeychainError(status: errSecAuthFailed)
        let session = AppSession(store: store)
        #expect(throws: KeychainError.self) { try session.disconnect() }
        #expect(session.credentials == credentials)
    }
}
