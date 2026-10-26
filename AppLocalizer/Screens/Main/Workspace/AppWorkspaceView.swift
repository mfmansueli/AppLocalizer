//
//  AppWorkspaceView.swift
//  AppLocalizer
//

import SwiftUI

/// The detail column for the selected app: the toolbar (title, section
/// picker, the assistant indicator while assistants matter, Refresh,
/// Activity and Review & Push) over the current section.
struct AppWorkspaceView: View {
    let app: StoreApp
    /// Every app in the library.
    let library: [StoreApp.ID]
    let services: WorkspaceServices

    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(ChangeQueue.self) private var changes
    @Environment(PushController.self) private var push
    @Environment(MCPServerController.self) private var assistants

    var body: some View {
        @Bindable var navigator = navigator
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
                if let notice = push.notice {
                    PushNoticeBanner(notice: notice, push: push) {
                        navigator.isReviewPresented = true
                    }
                }
            }
            .navigationTitle(app.name)
            .navigationSubtitle(app.bundleID)
            .toolbar(removing: .title)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    WorkspaceToolbarTitle(name: app.name, bundleID: app.bundleID)
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .principal) {
                    FittingSegmentedPicker(
                        label: String(localized: "Section"),
                        options: AppWorkspaceSection.allCases.map { ($0, $0.title) },
                        selection: $navigator.section
                    )
                    .fixedSize()
                    .accessibilityIdentifier("workspace.sectionPicker")
                }
                // The assistant shares Refresh and Activity's group: on its
                // own it pushed Review & Push into the overflow menu at the
                // default window width.
                ToolbarItemGroup(placement: .primaryAction) {
                    if assistantActivity.isVisible {
                        AssistantToolbarIndicator(activity: assistantActivity, appName: push.appName) { client in
                            navigator.reviewProposals(from: client)
                        }
                    }
                    Button {
                        navigator.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .help("Refresh from App Store Connect (⌘R)")
                    .accessibilityIdentifier("workspace.refreshButton")
                    Button {
                        navigator.isActivityPresented = true
                    } label: {
                        Label("Activity", systemImage: "clock")
                    }
                    .help("Activity")
                    .accessibilityIdentifier("workspace.activityButton")
                }
                ToolbarSpacer(.fixed, placement: .primaryAction)
                ToolbarItem(placement: .primaryAction) {
                    ReviewPushToolbarButton(count: changes.totalCount) {
                        navigator.isReviewPresented = true
                    }
                }
            }
    }

    private var assistantActivity: AssistantActivity {
        AssistantActivity(workingClient: assistants.isWorking ? assistants.workingClient : nil, changes: changes.changes, library: library)
    }

    @ViewBuilder
    private var content: some View {
        switch navigator.section {
        case .overview:
            OverviewSectionView(app: app)
        case .subscriptionPricing:
            PricingSectionView(app: app, services: services.pricing)
        case .storePage:
            StorePageSectionView(app: app, services: services.storePage)
        case .appInformation:
            AppInformationSectionView(app: app, services: services.appInformation)
        }
    }
}
