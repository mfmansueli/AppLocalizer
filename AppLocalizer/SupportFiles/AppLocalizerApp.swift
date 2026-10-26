//
//  AppLocalizerApp.swift
//  AppLocalizer
//

import SwiftUI

@main
struct AppLocalizerApp: App {
    @State private var session = AppSession(store: Self.credentialsStore, defaults: Self.defaults)
    @State private var changes: ChangeQueue
    @State private var history: PushHistory
    @State private var push: PushController
    @State private var pricingModes = PricingModeStore(defaults: Self.defaults)
    @State private var preferences = AppPreferences(defaults: Self.defaults)
    @State private var translation = TranslationPreferences(defaults: Self.defaults, secrets: Self.secretStore)
    @State private var assistants = MCPServerController(server: Self.httpServer, secrets: Self.secretStore, defaults: Self.defaults)

    init() {
        let changes = ChangeQueue(persistence: Self.changePersistence)
        let history = PushHistory(fileURL: Self.historyURL)
        _changes = State(initialValue: changes)
        _history = State(initialValue: history)
        _push = State(initialValue: PushController(queue: changes, history: history))
    }

    var body: some Scene {
        // One window: every app is a sidebar row, so a second window would
        // only duplicate the library and its requests.
        Window("AppLocalizer", id: "main") {
            RootView()
                .environment(session)
                .environment(changes)
                .environment(history)
                .environment(push)
                .environment(pricingModes)
                .environment(preferences)
                .environment(translation)
                .environment(assistants)
                .environment(\.keyChecker, Self.keyChecker)
                .frame(minWidth: Metrics.minimumWindowWidth, minHeight: Metrics.minimumWindowHeight)
                // The local MCP server runs while AppLocalizer is open, if
                // the person turned it on.
                .task { assistants.startIfEnabled() }
        }
        .defaultSize(width: 1200, height: 780)
        .commands {
            WorkspaceCommands()
            AccountCommands(session: session)
        }

        Settings {
            SettingsView(
                selection: Self.initialSettingsTab,
                opensPairing: Self.debugOpensPairing,
                scrollsToLog: Self.debugScrollsToLog
            )
            .environment(session)
            .environment(pricingModes)
            .environment(preferences)
            .environment(translation)
            .environment(assistants)
            .environment(\.keyChecker, Self.keyChecker)
        }
    }

    /// DEBUG scenes (and so UI tests) keep keys and secrets in memory, so
    /// they never read or overwrite the real ones in the Keychain.
    private static var credentialsStore: any CredentialsStore {
        #if DEBUG
        if let id = DebugScene.requestedID { return SettingsDebugScenes.credentialsStore(for: id) }
        #endif
        return KeychainCredentialsStore()
    }

    private static var secretStore: any SecretStore {
        #if DEBUG
        if let id = DebugScene.requestedID { return SettingsDebugScenes.secretStore(for: id) }
        #endif
        return KeychainSecretStore()
    }

    /// DEBUG scenes never open a port for the MCP server.
    private static var httpServer: any LocalHTTPServing {
        #if DEBUG
        if DebugScene.requestedID != nil { return DebugHTTPServer() }
        #endif
        return LocalHTTPServer()
    }

    /// DEBUG scenes check keys with canned answers, never with Apple.
    private static var keyChecker: any KeyChecker {
        #if DEBUG
        if let id = DebugScene.requestedID { return ConnectDebugScenes.keyChecker(for: id) }
        #endif
        return LiveKeyChecker()
    }

    private static var initialSettingsTab: SettingsTab {
        #if DEBUG
        if let tab = DebugScene.requestedID.flatMap(SettingsDebugScenes.tab(for:)) { return tab }
        #endif
        return .account
    }

    /// DEBUG scenes that open AI Assistants on the pairing sheet or the log.
    private static var debugOpensPairing: Bool {
        #if DEBUG
        DebugScene.requestedID.flatMap(SettingsDebugScenes.assistantsState(for:)) == .pairing
        #else
        false
        #endif
    }

    private static var debugScrollsToLog: Bool {
        #if DEBUG
        DebugScene.requestedID.flatMap(SettingsDebugScenes.assistantsState(for:)) == .log
        #else
        false
        #endif
    }

    /// DEBUG scenes keep pending changes, history and preferences in memory
    /// too, so they never touch the real ones.
    private static var isDebugScene: Bool {
        #if DEBUG
        DebugScene.requestedID != nil
        #else
        false
        #endif
    }

    private static var changePersistence: (any ChangeQueuePersistence)? {
        isDebugScene ? nil : FileChangeQueuePersistence()
    }

    private static var historyURL: URL? {
        isDebugScene ? nil : PushHistory.defaultFileURL
    }

    private static var defaults: UserDefaults? {
        isDebugScene ? nil : .standard
    }
}
