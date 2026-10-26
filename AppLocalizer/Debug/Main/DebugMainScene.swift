//
//  DebugMainScene.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// The main window with the sample account and canned services, starting on
/// one app and section. Every section's DEBUG scenes build on it, swapping
/// single services to reach a state.
struct DebugMainScene: View {
    private let services: WorkspaceServices
    private let selectedAppID: StoreApp.ID?
    private let section: AppWorkspaceSection
    @State private var changes: ChangeQueue
    @State private var history: PushHistory
    @State private var push: PushController
    @State private var pricingModes: PricingModeStore
    private let autoPush: Bool
    private let presentedSheet: WorkspaceSheet?
    private let notice: PushNotice?
    private let isFirstSync: Bool
    @Environment(AppSession.self) private var session

    init(
        services: WorkspaceServices = .debug,
        selectedAppID: StoreApp.ID? = DebugFixtures.AppID.lumen,
        section: AppWorkspaceSection = .overview,
        pendingChanges: [PendingChange] = DebugWorkspace.pendingChanges,
        pushRecords: [PushRecord] = DebugWorkspace.pushRecords,
        pricingModes: [StoreApp.ID: PricingMode] = DebugWorkspace.pricingModes,
        presentedSheet: WorkspaceSheet? = nil,
        autoPush: Bool = false,
        notice: PushNotice? = nil,
        isFirstSync: Bool = false
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
        _push = State(initialValue: PushController(queue: changes, history: history, transport: services.push))
        _pricingModes = State(initialValue: PricingModeStore(defaults: nil, modes: pricingModes))
    }

    var body: some View {
        MainView(
            services: services,
            accounts: DebugFixtures.accounts,
            currentAccountID: DebugFixtures.northpier.id,
            selectedAppID: selectedAppID,
            section: section,
            presentedSheet: presentedSheet,
            isFirstSync: isFirstSync,
            onAddKey: { session.isAddingKey = true }
        )
        .environment(changes)
        .environment(history)
        .environment(push)
        .environment(pricingModes)
        .task {
            // Push scenes start with every pending change already sending.
            if autoPush, push.phase == .idle { push.push(changes.changes) }
            if let notice { push.report(notice) }
        }
    }
}
#endif
