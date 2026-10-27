//
//  TemplateProposalDetailView.swift
//  AppLocalizer
//

import SwiftUI

/// A template proposal: for a stale one, what changed since and the pick
/// for each path both sides changed; then its changes as old → new, and
/// the stress strip before and after on a chosen slot.
struct TemplateProposalDetailView: View {
    @Bindable var viewModel: ScreenshotProposalsViewModel
    let proposal: ScreenshotProposal

    var body: some View {
        if let review = viewModel.review(of: proposal) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                if proposal.isWaiting, review.isStale {
                    ProposalStaleBox(viewModel: viewModel, proposal: proposal, review: review)
                }
                changes(review)
                ProposalStressStripView(viewModel: viewModel, proposal: proposal)
            }
        }
    }

    private func changes(_ review: TemplateProposalReview) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            sectionTitle(String(localized: "Changes"))
            VStack(spacing: 0) {
                ForEach(Array(review.rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { Divider() }
                    HStack(spacing: Spacing.small) {
                        Text(row.change.title)
                            .font(.callout)
                        Spacer(minLength: Spacing.medium)
                        Text(Self.valueText(row.change.oldText))
                            .font(.callout)
                            .foregroundStyle(Palette.label2)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(Palette.label3)
                            .accessibilityLabel(Text("to"))
                        Text(Self.valueText(row.change.newText))
                            .font(.callout.weight(.semibold))
                        if row.isConflict, proposal.isWaiting {
                            Pill(text: String(localized: "Conflict"), style: .warning)
                        }
                    }
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("proposals.change.\(row.id)")
                }
            }
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.field + 2, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.field + 2, style: .continuous)
                    .strokeBorder(Palette.separator, lineWidth: 0.5)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(Palette.label2)
    }

    /// A value as the design's change rows show it: "Off → On".
    private static func valueText(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }
}
