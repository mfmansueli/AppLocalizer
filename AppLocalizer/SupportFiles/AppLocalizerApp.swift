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
    @State private var preferences: AppPreferences
    @State private var translation: TranslationPreferences
    @State private var assistants: MCPServerController
    @State private var keyAssistant: KeyAssistantController
    @State private var launcher: ClaudeCodeLauncher
    @State private var suggestions = FieldSuggestionStore(persistence: Self.suggestionPersistence)

    init() {
        let changes = ChangeQueue(persistence: Self.changePersistence)
        let history = PushHistory(fileURL: Self.historyURL)
        _changes = State(initialValue: changes)
        _history = State(initialValue: history)
        _push = State(initialValue: PushController(queue: changes, history: history))
        let preferences = AppPreferences(defaults: Self.defaults)
        _preferences = State(initialValue: preferences)
        let translation = TranslationPreferences(defaults: Self.defaults, secrets: Self.secretStore)
        let keyAssistant = KeyAssistantController(
            service: Self.keyAssistantService,
            secrets: Self.secretStore,
            defaults: Self.defaults,
            translation: translation
        )
        let assistants = MCPServerController(server: Self.httpServer, secrets: Self.secretStore, defaults: Self.defaults, port: Self.mcpPort)
        assistants.keyAssistant = keyAssistant
        let launcher = ClaudeCodeLauncher(
            assistants: assistants, runner: Self.scriptRunner, defaults: Self.defaults, simulatorRunner: Self.simulatorRunner
        )
        #if DEBUG
        if let id = DebugScene.requestedID { ClaudeCodeDebugScenes.configure(launcher, for: id) }
        #endif
        if Self.continuesAutopilot {
            // A Claude Code that stops with captures left is started again.
            launcher.onRunEnded = { [weak launcher] session in
                guard let launcher else { return }
                Task { await AutopilotContinuation.sessionEnded(session, center: .shared, launcher: launcher) }
            }
            // Autopilot says when a run needs the person.
            AutopilotCenter.shared.onStageChange = { run, old in
                guard let turn = AutopilotTurn.turn(from: old, to: run.stage) else { return }
                AutopilotTurnNotifier.shared.post(turn, run: run, appName: AutopilotTurnNotifier.appName(of: run))
            }
        }
        _translation = State(initialValue: translation)
        _keyAssistant = State(initialValue: keyAssistant)
        _assistants = State(initialValue: assistants)
        _launcher = State(initialValue: launcher)
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
                .environment(keyAssistant)
                .environment(launcher)
                .environment(suggestions)
                .environment(\.keyChecker, Self.keyChecker)
                .frame(minWidth: Metrics.minimumWindowWidth, minHeight: Metrics.minimumWindowHeight)
                // The local MCP server runs while AppLocalizer is open, if
                // the person turned it on.
                .task { assistants.startIfEnabled() }
                // Whether the helper is there to start Claude Code.
                .task { await launcher.refreshHelper() }
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
            .environment(keyAssistant)
            .environment(launcher)
            .environment(\.keyChecker, Self.keyChecker)
            .environment(\.aiProviderKeyChecker, Self.aiProviderKeyChecker)
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

    /// DEBUG scenes never open a port for the MCP server, except
    /// `cc-live`, which runs the real Claude Code on a port of its own;
    /// nor does the unit tests' host (`UnitTestHost`).
    private static var httpServer: any LocalHTTPServing {
        #if DEBUG
        if UnitTestHost.isRunning { return DebugHTTPServer() }
        if let id = DebugScene.requestedID, !ClaudeCodeDebugScenes.isLive(id) { return DebugHTTPServer() }
        #endif
        return LocalHTTPServer()
    }

    private static var mcpPort: UInt16 {
        #if DEBUG
        if let id = DebugScene.requestedID, ClaudeCodeDebugScenes.isLive(id) { return ClaudeCodeDebugScenes.livePort }
        #endif
        return MCPEndpoint.defaultPort
    }

    /// DEBUG scenes start a pretend Claude Code that answers from canned
    /// lines, never the real one.
    private static var scriptRunner: any UnixScriptRunning {
        #if DEBUG
        if let id = DebugScene.requestedID { return ClaudeCodeDebugScenes.scriptRunner(for: id) }
        #endif
        return LiveUnixScriptRunner()
    }

    /// Autopilot's runs go on when Claude Code stops early; DEBUG scenes keep
    /// their own runs, never the real ones.
    private static var continuesAutopilot: Bool {
        #if DEBUG
        if DebugScene.requestedID != nil { return false }
        #endif
        return true
    }

    /// DEBUG scenes read a pretend Mac's simulators; nil uses the helper's
    /// runner.
    private static var simulatorRunner: (any UnixScriptRunning)? {
        #if DEBUG
        if let id = DebugScene.requestedID, !ClaudeCodeDebugScenes.isLive(id) { return DebugUnixScriptRunner.simulators }
        #endif
        return nil
    }

    /// DEBUG scenes check keys with canned answers, never with Apple.
    private static var keyChecker: any KeyChecker {
        #if DEBUG
        if let id = DebugScene.requestedID { return ConnectDebugScenes.keyChecker(for: id) }
        #endif
        return LiveKeyChecker()
    }

    /// DEBUG scenes answer API key requests from canned data, never from
    /// the vendor.
    private static var keyAssistantService: any KeyAssistantService {
        #if DEBUG
        if DebugScene.requestedID != nil { return DebugKeyAssistantService() }
        #endif
        return LiveKeyAssistantService()
    }

    /// DEBUG scenes check AI provider keys with canned answers, never with
    /// the vendor.
    private static var aiProviderKeyChecker: any AIProviderKeyChecker {
        #if DEBUG
        if DebugScene.requestedID != nil { return DebugAIProviderKeyChecker() }
        #endif
        return LiveAIProviderKeyChecker()
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

    private static var suggestionPersistence: (any FieldSuggestionPersistence)? {
        isDebugScene ? nil : FileFieldSuggestionPersistence()
    }

    private static var historyURL: URL? {
        isDebugScene ? nil : PushHistory.defaultFileURL
    }

    private static var defaults: UserDefaults? {
        isDebugScene ? nil : .standard
    }
}
