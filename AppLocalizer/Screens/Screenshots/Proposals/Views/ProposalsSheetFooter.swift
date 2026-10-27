//
//  ProposalsSheetFooter.swift
//  AppLocalizer
//

import SwiftUI

/// The selected proposal's decision: Reject or Accept as v5 for a
/// template; Reject All, Accept n Selected or Accept All for captions;
/// Done when it's stale (it's rebased or discarded above) or decided.
struct ProposalsSheetFooter: View {
    @Bindable var viewModel: ScreenshotProposalsViewModel
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: Spacing.small) {
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
                    .lineLimit(2)
            }
            if let proposal = viewModel.selected, proposal.isWaiting, viewModel.status(of: proposal) != .stale {
                buttons(for: proposal)
            } else {
                Spacer()
                Button("Done", action: onClose)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("proposals.done")
            }
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }

    @ViewBuilder
    private func buttons(for proposal: ScreenshotProposal) -> some View {
        switch proposal.kind {
        case .template:
            Button("Reject") { Task { await viewModel.reject() } }
                .foregroundStyle(Palette.danger)
                .accessibilityIdentifier("proposals.reject")
            Spacer()
            Button("Close", action: onClose)
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("proposals.close")
            Button("Accept as v\((viewModel.currentVersion ?? 0) + 1)") { Task { await viewModel.acceptTemplate() } }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.acceptRefusal(of: proposal) != nil)
                .help(viewModel.acceptRefusal(of: proposal) ?? "")
                .accessibilityIdentifier("proposals.acceptTemplate")
        case .captions:
            Button("Reject All") { Task { await viewModel.reject() } }
                .foregroundStyle(Palette.danger)
                .accessibilityIdentifier("proposals.rejectAll")
            Spacer()
            Button("Close", action: onClose)
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("proposals.close")
            Button(viewModel.acceptSelectedTitle(of: proposal)) { Task { await viewModel.acceptCaptions(all: false) } }
                .disabled(!viewModel.canAcceptSelected(proposal))
                .accessibilityIdentifier("proposals.acceptSelected")
            Button("Accept All") { Task { await viewModel.acceptCaptions(all: true) } }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("proposals.acceptAll")
        }
    }
}
