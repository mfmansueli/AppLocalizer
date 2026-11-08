//
//  AppWorkspaceView.swift
//  AppLocalizer
//

import SwiftUI

/// The detail column for the selected app: the toolbar (title, section
/// picker, the Assistant button, Refresh, Activity and Review & Push) over
/// the current section, and the window's toasts (Suggest Everything's
/// total when it finishes).
struct AppWorkspaceView: View {
    let app: StoreApp
    /// Every app in the library.
    let library: [StoreApp.ID]
    let services: WorkspaceServices

    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(ChangeQueue.self) private var changes
    @Environment(PushController.self) private var push
    @Environment(MCPServerController.self) private var assistants
    @Environment(FieldSuggestionStore.self) private var suggestions
    @State private var toolbarLayout = WorkspaceToolbarLayout()

    var body: some View {
        @Bindable var navigator = navigator
        // The banner sits above the section, not in its safe area: one that
        // appears after a push ends would otherwise cover what the section
        // had already scrolled into place.
        VStack(spacing: 0) {
            if let notice = push.notice {
                PushNoticeBanner(notice: notice, push: push) {
                    navigator.isReviewPresented = true
                }
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // The app's name and bundle ID sit in the toolbar without a
                // glass background of their own: the hard edge keeps them
                // readable over whatever scrolls under the toolbar.
                .scrollEdgeEffectStyle(.hard, for: .top)
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { toolbarLayout.detailWidth = $0 }
        .overlay(alignment: .bottom) {
            if let toast = navigator.toast {
                ActionToast(message: toast.message) {
                    undo(toast)
                } onAction: {
                    act(on: toast)
                } onDismiss: {
                    if navigator.toast?.id == toast.id { navigator.toast = nil }
                }
                .padding(Spacing.large)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: navigator.toast?.id)
        .onChange(of: suggestions.run) { old, new in
            guard let new, new.phase == .finished, old?.id != new.id || old?.phase != .finished else { return }
            navigator.toast = .finished(new)
        }
        .navigationTitle(app.name)
        .navigationSubtitle(app.bundleID)
        .toolbar(removing: .title)
        .toolbar {
            // Two items rather than one that resizes: a toolbar item keeps
            // the size it first had.
            if toolbarLayout.isTitleCompact {
                ToolbarItem(placement: .navigation) {
                    WorkspaceToolbarTitle(name: app.name, bundleID: app.bundleID, width: WorkspaceToolbarLayout.compactTitleWidth)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .navigation) {
                    WorkspaceToolbarTitle(name: app.name, bundleID: app.bundleID)
                }
                .sharedBackgroundVisibility(.hidden)
            }
            // Right after the title, as the design draws it: centered as
            // `.principal`, it left a gap that pushed Review & Push into
            // the overflow menu.
            ToolbarItem(placement: .navigation) {
                FittingSegmentedPicker(
                    label: String(localized: "Section"),
                    options: AppWorkspaceSection.allCases.map { ($0, $0.title) },
                    selection: $navigator.section
                )
                .fixedSize()
                .onGeometryChange(for: CGFloat.self, of: \.size.width) { toolbarLayout.pickerWidth = $0 }
                .accessibilityIdentifier("workspace.sectionPicker")
            }
            // Keeps the actions at the trailing edge.
            ToolbarSpacer(.flexible)
            // The assistant shares Refresh and Activity's group: on its
            // own it pushed Review & Push into the overflow menu at the
            // default window width.
            ToolbarItemGroup(placement: .primaryAction) {
                AssistantToolbarIndicator(
                    activity: assistantActivity,
                    status: assistants.assistantStatus,
                    client: assistants.assistantClient,
                    editsDrafts: assistants.editsDrafts,
                    recentCalls: assistants.leadingClient.map { assistants.recentCalls(of: $0.name) } ?? [],
                    center: screenshotDocuments,
                    appName: push.appName,
                    onReview: { client in navigator.reviewProposals(from: client) },
                    isSuggestingEverything: suggestions.run?.isRunning == true,
                    canAskAboutPage: navigator.section == .storePage || navigator.section == .appInformation,
                    onAsk: askForSuggestions,
                    onSuggestEverything: suggestEverything,
                    onSetUp: { navigator.isAssistantSetupPresented = true }
                )
                .onGeometryChange(for: CGFloat.self, of: \.size.width) { toolbarLayout.indicatorWidth = $0 }
                .onDisappear { toolbarLayout.indicatorWidth = 0 }
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
                ReviewPushToolbarButton(count: changes.totalCount + push.screenshots.imageCount + push.screenshots.extras.itemCount) {
                    navigator.isReviewPresented = true
                }
            }
        }
    }

    private var assistantActivity: AssistantActivity {
        AssistantActivity(
            workingClient: assistants.isWorking ? assistants.workingClient : nil,
            changes: changes.changes,
            library: library,
            screenshotProposals: screenshotDocuments?.waitingClients(in: library) ?? [:],
            keepsVisible: screenshotDocuments?.presentedProposals != nil
        )
    }

    /// "Ask for Suggestions…": App Information's page when it's open, else
    /// the Store Page, which copies the prompt and waits.
    /// An API key only generates Store Page text.
    private func askForSuggestions() {
        let onInformation = navigator.section == .appInformation && !assistants.assistantStatus.isReady
        let area: SuggestionArea = onInformation ? .appInformation : .storePage
        navigator.open(area.section, intent: .askForSuggestions(area), appID: app.id)
    }

    /// Suggest Everything… starts it on Overview; Show Progress, while it
    /// runs, opens the run's Overview.
    private func suggestEverything() {
        if let run = suggestions.run, run.isRunning {
            navigator.open(.overview, appID: run.appID)
        } else {
            navigator.suggestEverything()
        }
    }

    private func undo(_ toast: WorkspaceToast) {
        guard let undo = toast.undo else { return }
        SuggestionRunAcceptance.undo(undo, queue: changes, store: suggestions)
        navigator.toast = nil
    }

    private func act(on toast: WorkspaceToast) {
        navigator.toast = nil
        switch toast.action {
        case let .openOverview(appID): navigator.open(.overview, appID: appID)
        case .suggestEverything: navigator.suggestEverything()
        case nil: break
        }
    }

    /// Screenshot proposals waiting per app, and their sheet.
    private var screenshotDocuments: ScreenshotsDocumentCenter? {
        services.screenshots.documentCenter
    }

    @ViewBuilder
    private var content: some View {
        switch navigator.section {
        case .overview:
            OverviewSectionView(app: app)
        case .subscriptionPricing:
            PricingSectionView(app: app, services: services.pricing, retention: services.retention)
        case .storePage:
            StorePageSectionView(app: app, services: services.storePage)
        case .screenshots:
            ScreenshotsSectionView(app: app, services: services.storePage)
        case .appInformation:
            AppInformationSectionView(app: app, services: services.appInformation)
        }
    }
}
