//
//  AssistantToolbarIndicator.swift
//  AppLocalizer
//

import SwiftUI

/// The toolbar's quiet assistant indicator: "CC Claude Code" with a spinner
/// while an assistant works, "CC 2 proposals" while its proposals wait.
/// Never modal; clicking it lists what waits per app, with Review
/// Proposals… opening Review & Push filtered to that assistant.
struct AssistantToolbarIndicator: View {
    let activity: AssistantActivity
    /// The name of an app in the library, by Apple ID.
    let appName: (StoreApp.ID) -> String
    let onReview: (_ client: String?) -> Void
    @State private var isShowingProposals = false

    var body: some View {
        Button {
            isShowingProposals.toggle()
        } label: {
            HStack(spacing: Spacing.xSmall) {
                if let client = activity.client {
                    AssistantMonogram(letters: ChangeSource.assistant(client: client).monogram ?? "AI")
                }
                Text(activity.title)
                    .lineLimit(1)
                if activity.isWorking {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .help(activity.accessibilityLabel)
        .accessibilityLabel(Text(activity.accessibilityLabel))
        .accessibilityIdentifier("workspace.assistantIndicator")
        .popover(isPresented: $isShowingProposals, arrowEdge: .bottom) {
            popover
        }
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
            Button("Review Proposals…") {
                isShowingProposals = false
                onReview(activity.leadingClient)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(activity.apps.isEmpty)
            .padding(.top, Spacing.xSmall)
            .accessibilityIdentifier("workspace.reviewProposals")
        }
        .padding(Spacing.medium)
        .frame(width: 280, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspace.assistantPopover")
    }
}
