//
//  AssistantToolbarIndicator.swift
//  AppLocalizer
//

import SwiftUI

/// The toolbar's Assistant button, always there: a dot for how far the
/// person's own assistant is set up (grey, yellow, green), a spinner while
/// it works, and the count of its proposals waiting. Never modal; clicking
/// it shows the status, recent calls and what waits per app, with Review
/// Proposals… opening Review & Push filtered to that assistant (or, for
/// screenshot proposals, their Proposals sheet), and Ask for Suggestions…
/// or Set Up Assistant….
struct AssistantToolbarIndicator: View {
    let activity: AssistantActivity
    let status: AssistantStatus
    /// The client the button names, once paired.
    var client: MCPPairedClient?
    var editsDrafts = false
    var recentCalls: [MCPLogEntry] = []
    /// Holds the Proposals sheet; nil when these services keep no screenshot
    /// documents.
    let center: ScreenshotsDocumentCenter?
    /// The name of an app in the library, by Apple ID.
    let appName: (StoreApp.ID) -> String
    let onReview: (_ client: String?) -> Void
    var onAsk: () -> Void = {}
    var onSetUp: () -> Void = {}
    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(KeyAssistantController.self) private var keyAssistant
    @State private var isShowingPopover = false

    var body: some View {
        Button {
            isShowingPopover.toggle()
        } label: {
            HStack(spacing: Spacing.xSmall) {
                if activity.isWorking {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    AssistantStatusDot(status: status)
                }
                Text("Assistant")
                    .font(.caption)
                    .lineLimit(1)
                if activity.proposalCount > 0 {
                    Text(activity.proposalCount, format: .number)
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .padding(.horizontal, 5)
                        .background(Palette.accentTint, in: Capsule())
                }
            }
        }
        .help(accessibilityLabel)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityIdentifier("workspace.assistantIndicator")
        .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
            AssistantPopoverContent(
                status: status,
                activity: activity,
                client: client,
                editsDrafts: editsDrafts,
                recentCalls: recentCalls,
                key: keyAssistant.configuration,
                recentRequests: keyAssistant.recentRequests,
                appName: appName,
                canOpenScreenshotProposals: screenshotApp != nil,
                onReviewProposals: reviewProposals,
                onScreenshotProposals: {
                    isShowingPopover = false
                    if let screenshotApp { center?.openProposals(appID: screenshotApp) }
                },
                onAsk: {
                    isShowingPopover = false
                    onAsk()
                },
                onSetUp: {
                    isShowingPopover = false
                    onSetUp()
                }
            )
        }
        .sheet(item: presentedProposals) { proposals in
            ScreenshotProposalsSheet(viewModel: proposals)
        }
        .onChange(of: navigator.requestsAssistantPopover, initial: true) {
            guard navigator.requestsAssistantPopover else { return }
            navigator.requestsAssistantPopover = false
            isShowingPopover = true
        }
        #if DEBUG
        .task {
            if Self.debugShowsPopover {
                Self.debugShowsPopover = false
                isShowingPopover = true
            }
        }
        #endif
    }

    /// "Claude Code is proposing changes", "2 proposals waiting for
    /// review", or "Assistant, Connected".
    private var accessibilityLabel: String {
        if activity.isWorking || activity.proposalCount > 0 { return activity.accessibilityLabel }
        return String(localized: "Assistant, \(status.title)")
    }

    /// The app whose screenshot proposals open: the one with the most.
    private var screenshotApp: StoreApp.ID? {
        activity.screenshotApps.map(\.appID).first { center?.canOpenProposals(appID: $0) == true }
    }

    private var presentedProposals: Binding<ScreenshotProposalsViewModel?> {
        Binding { center?.presentedProposals } set: { center?.presentedProposals = $0 }
    }

    private func reviewProposals() {
        isShowingPopover = false
        if activity.reviewCount == 0, let screenshotApp {
            center?.openProposals(appID: screenshotApp)
        } else {
            onReview(activity.leadingReviewClient ?? activity.leadingClient)
        }
    }
}
