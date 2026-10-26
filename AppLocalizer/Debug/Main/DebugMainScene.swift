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
    @State private var pricingModes: PricingModeStore

    init(
        services: WorkspaceServices = .debug,
        selectedAppID: StoreApp.ID? = DebugFixtures.AppID.lumen,
        section: AppWorkspaceSection = .overview,
        pendingChanges: [PendingChange] = DebugWorkspace.pendingChanges,
        pushRecords: [PushRecord] = DebugWorkspace.pushRecords,
        pricingModes: [StoreApp.ID: PricingMode] = DebugWorkspace.pricingModes
    ) {
        self.services = services
        self.selectedAppID = selectedAppID
        self.section = section
        _changes = State(initialValue: ChangeQueue(changes: pendingChanges))
        _history = State(initialValue: PushHistory(records: pushRecords))
        _pricingModes = State(initialValue: PricingModeStore(defaults: nil, modes: pricingModes))
    }

    var body: some View {
        MainView(
            services: services,
            accounts: DebugFixtures.accounts,
            currentAccountID: DebugFixtures.northpier.id,
            selectedAppID: selectedAppID,
            section: section
        )
        .environment(changes)
        .environment(history)
        .environment(pricingModes)
    }
}
#endif
