//
//  AssistantToolbarIndicator.swift
//  AppLocalizer
//

import SwiftUI

/// The toolbar's quiet assistant indicator: "CC Claude Code" with a spinner
/// while an assistant works, "CC 2 proposals" while its proposals wait.
/// Never modal; clicking it lists what waits per app, with Review
/// Proposals… opening Review & Push filtered to that assistant, or, for
/// screenshot proposals, their Proposals sheet.
struct AssistantToolbarIndicator: View {
    let activity: AssistantActivity
    /// The name of an app in the library, by Apple ID.
    let appName: (StoreApp.ID) -> String
    let onReview: (_ client: String?) -> Void
    @State private var isShowingProposals = false
    @State private var center = ScreenshotsDocumentCenter.shared

    var body: some View {
        Button {
            isShowingProposals.toggle()
        } label: {
            HStack(spacing: Spacing.xSmall) {
                if let client = activity.client {
                    AssistantMonogram(letters: ChangeSource.assistant(client: client).monogram ?? "AI")
                }
                Text(activity.title)
                    .font(.caption)
                    .lineLimit(1)
                if activity.isWorking {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
        }
        .help(activity.accessibilityLabel)
        .accessibilityLabel(Text(activity.accessibilityLabel))
        .accessibilityIdentifier("workspace.assistantIndicator")
        .popover(isPresented: $isShowingProposals, arrowEdge: .bottom) {
            popover
        }
        .sheet(item: $center.presentedProposals) { proposals in
            ScreenshotProposalsSheet(viewModel: proposals)
        }
        #if DEBUG
        .task {
            if Self.debugShowsPopover {
                Self.debugShowsPopover = false
                isShowingProposals = true
            }
        }
        #endif
    }

    /// The app whose screenshot proposals open: the one with the most whose
    /// document was read this launch.
    private var screenshotApp: StoreApp.ID? {
        activity.screenshotApps.map(\.appID).first { center.canOpenProposals(appID: $0) }
    }

    private var popover: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Waiting for you")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Palette.label2)
                .padding(.bottom, Spacing.xxSmall)
            if activity.rows.isEmpty {
                Text("Nothing yet. Proposals show here as \(activity.client ?? String(localized: "the assistant")) sends them.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(activity.rows) { entry in
                HStack {
                    Text(appName(entry.appID))
                        .lineLimit(1)
                    Spacer(minLength: Spacing.large)
                    Text(AssistantActivity.proposalsText(entry.count))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(entry.count == 0 ? Palette.label3 : Palette.label2)
                }
                .accessibilityElement(children: .combine)
            }
            HStack(spacing: Spacing.xSmall) {
                Button("Review Proposals…") {
                    isShowingProposals = false
                    if activity.reviewCount == 0, let screenshotApp {
                        center.openProposals(appID: screenshotApp)
                    } else {
                        onReview(activity.leadingReviewClient ?? activity.leadingClient)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(activity.apps.isEmpty || (activity.reviewCount == 0 && screenshotApp == nil))
                .accessibilityIdentifier("workspace.reviewProposals")
                if activity.reviewCount > 0, let screenshotApp {
                    Button("Screenshot Proposals…") {
                        isShowingProposals = false
                        center.openProposals(appID: screenshotApp)
                    }
                    .accessibilityIdentifier("workspace.screenshotProposals")
                }
            }
            .controlSize(.small)
            .padding(.top, Spacing.xSmall)
        }
        .padding(Spacing.medium)
        .frame(width: 280, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspace.assistantPopover")
    }
}
