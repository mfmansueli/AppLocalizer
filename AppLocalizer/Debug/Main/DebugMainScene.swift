//
//  DebugMainScene.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// The main window with the sample account and canned services, starting on
/// one app and section. Every section's DEBUG scenes build on it, swapping
/// single services to reach a state. With `unnamedKey` the account is a
/// key the person hasn't named, so the switcher shows the name the app list
/// services give the team.
struct DebugMainScene: View {
    private let services: WorkspaceServices
    private let selectedAppID: StoreApp.ID?
    private let section: AppWorkspaceSection
    @State private var changes: ChangeQueue
    @State private var history: PushHistory
    @State private var push: PushController
    @State private var pricingModes: PricingModeStore
    @State private var suggestions: FieldSuggestionStore
    private let autoPush: Bool
    private let presentedSheet: WorkspaceSheet?
    private let notice: PushNotice?
    private let isFirstSync: Bool
    /// The unnamed key's own session; nil shows the sample accounts.
    @State private var keySession: AppSession?
    @Environment(AppSession.self) private var session

    init(
        services: WorkspaceServices = .debug,
        selectedAppID: StoreApp.ID? = DebugFixtures.AppID.lumen,
        section: AppWorkspaceSection = .overview,
        pendingChanges: [PendingChange] = DebugWorkspace.pendingChanges,
        pushRecords: [PushRecord] = DebugWorkspace.pushRecords,
        pricingModes: [StoreApp.ID: PricingMode] = DebugWorkspace.pricingModes,
        suggestions: FieldSuggestionStore = FieldSuggestionStore(),
        presentedSheet: WorkspaceSheet? = nil,
        autoPush: Bool = false,
        notice: PushNotice? = nil,
        isFirstSync: Bool = false,
        unnamedKey: Bool = false
    ) {
        self.services = services
        self.selectedAppID = selectedAppID
        self.section = section
        self.autoPush = autoPush
        self.presentedSheet = presentedSheet
        self.notice = notice
        self.isFirstSync = isFirstSync
        let changes = ChangeQueue(changes: pendingChanges)
        let history = PushHistory(records: pushRecords)
        _changes = State(initialValue: changes)
        _history = State(initialValue: history)
        // The scene's in-memory secrets, e.g. App Review's demo password, so
        // pushing in a scene never reads the Keychain.
        _push = State(initialValue: PushController(queue: changes, history: history, transport: services.push, secrets: services.appInformation.secrets))
        _pricingModes = State(initialValue: PricingModeStore(defaults: nil, modes: pricingModes))
        _suggestions = State(initialValue: suggestions)
        let key = AppStoreConnectCredentials(issuerID: DebugFixtures.issuerID, keyID: DebugFixtures.keyID, privateKeyPEM: DebugFixtures.privateKey.pem)
        _keySession = State(initialValue: unnamedKey ? AppSession(store: DebugCredentialsStore(keys: [key])) : nil)
    }

    var body: some View {
        MainView(
            services: services,
            accounts: keySession?.accounts ?? DebugFixtures.accounts,
            currentAccountID: keySession?.currentKeyID ?? DebugFixtures.northpier.id,
            selectedAppID: selectedAppID,
            section: section,
            presentedSheet: presentedSheet,
            isFirstSync: isFirstSync,
            onAddKey: { session.isAddingKey = true },
            onTeamNameFound: { keySession?.recordTeamName($0, for: DebugFixtures.keyID) }
        )
        .environment(changes)
        .environment(history)
        .environment(push)
        .environment(pricingModes)
        .environment(suggestions)
        .task {
            // Push scenes start with every pending change already sending.
            if autoPush, push.phase == .idle { push.push(changes.changes) }
            if let notice { push.report(notice) }
        }
    }
}
#endif
