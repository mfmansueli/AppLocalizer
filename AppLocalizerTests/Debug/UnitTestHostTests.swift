//
//  UnitTestHostTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// These tests run inside the app: it knows, so it opens no MCP port and
/// keeps no Autopilot runs on disk while the person's own AppLocalizer may
/// be open.
@Suite("Unit test host")
struct UnitTestHostTests {
    @Test func theAppKnowsItHostsTheTests() {
        #expect(UnitTestHost.isRunning, "Without it, the host takes the open app's MCP calls")
    }

    /// A test build isn't signed like the person's app, so every Keychain
    /// read would ask for their login password.
    @Test func theHostKeepsKeysAndSecretsInMemory() {
        #expect(AppLocalizerApp.secretStore is InMemorySecretStore)
        #expect(AppLocalizerApp.credentialsStore is DebugCredentialsStore)
    }

    @Test func aNormalLaunchIsNoTestHost() {
        #expect(!UnitTestHost.isRunning(in: [:]))
        #expect(!UnitTestHost.isRunning(in: ["PATH": "/usr/bin"]))
        #expect(UnitTestHost.isRunning(in: ["XCTestConfigurationFilePath": "/tmp/x.xctestconfiguration"]))
    }
}
#endif
