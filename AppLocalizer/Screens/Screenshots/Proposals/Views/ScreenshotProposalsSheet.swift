//
//  ScreenshotProposalsSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Proposals · Lumen Journal (design `prop-tpl`, `prop-cap`, `prop-stale`,
/// `prop-disc`): the app's screenshot proposals on the left, the selected
/// one on the right, its decision in the footer.
struct ScreenshotProposalsSheet: View {
    @Bindable var viewModel: ScreenshotProposalsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ProposalsSheetHeader(viewModel: viewModel)
            Divider()
            HStack(spacing: 0) {
                list
                Divider()
                detail
            }
            Divider()
            ProposalsSheetFooter(viewModel: viewModel) { dismiss() }
        }
        .frame(minWidth: 960, idealWidth: 980, minHeight: 640, idealHeight: 700)
        .task { await viewModel.load() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("proposals.sheet")
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: Spacing.small) {
                ForEach(viewModel.proposals) { proposal in
                    ProposalCardView(
                        proposal: proposal, subtitle: viewModel.subtitle(of: proposal), status: viewModel.status(of: proposal),
                        isSelected: viewModel.selectedID == proposal.id
                    ) {
                        viewModel.selectedID = proposal.id
                    }
                }
                if viewModel.proposals.isEmpty {
                    Text("Nothing yet. Proposals show here as assistants send them.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .padding(Spacing.medium)
                }
            }
            .padding(Spacing.medium)
        }
        .frame(width: 270)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("proposals.list")
    }

    @ViewBuilder
    private var detail: some View {
        if let proposal = viewModel.selected {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    ProposalDetailHeader(proposal: proposal, meta: viewModel.meta(of: proposal), outcome: viewModel.outcome(of: proposal))
                    switch proposal.kind {
                    case .template: TemplateProposalDetailView(viewModel: viewModel, proposal: proposal)
                    case .captions: CaptionProposalDetailView(viewModel: viewModel, proposal: proposal)
                    }
                }
                .padding(Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .id(proposal.id)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("proposals.detail")
        } else {
            ContentUnavailableView("No proposal selected", systemImage: "tray")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
