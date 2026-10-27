//
//  ProposalStaleBox.swift
//  AppLocalizer
//

import SwiftUI

/// "Based on template v3. The template is now v4.": what changed since,
/// and for each path both sides changed, keep yours or use the
/// assistant's; then Rebase onto v4, or Discard.
struct ProposalStaleBox: View {
    @Bindable var viewModel: ScreenshotProposalsViewModel
    let proposal: ScreenshotProposal
    let review: TemplateProposalReview

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Based on template v\(proposal.basedOnVersion ?? 0). The template is now v\(review.currentNumber).")
                .font(.callout.weight(.semibold))
            ForEach(review.versionsSince, id: \.number) { version in
                Text("Since then · \(viewModel.sinceText(version))")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            ForEach(review.conflicts) { row in
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("\(Text(row.change.title).fontWeight(.semibold)) changed in both. Pick one to rebase:")
                        .font(.caption)
                    HStack(spacing: Spacing.xSmall) {
                        choiceButton(String(localized: "Keep yours · \(row.currentText)"), choice: .keepYours, row: row)
                            .accessibilityIdentifier("proposals.keepYours")
                        choiceButton(String(localized: "Use \(proposal.client)’s · \(row.change.newText)"), choice: .useTheirs, row: row)
                            .accessibilityIdentifier("proposals.useTheirs")
                    }
                }
            }
            HStack(spacing: Spacing.xSmall) {
                Button("Rebase onto v\(review.currentNumber)") {
                    Task { await viewModel.rebase() }
                }
                .accessibilityIdentifier("proposals.rebase")
                Button("Discard", role: .destructive) {
                    Task { await viewModel.reject() }
                }
                .foregroundStyle(Palette.danger)
                .accessibilityIdentifier("proposals.discard")
            }
            .controlSize(.small)
            .padding(.top, Spacing.xxSmall)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.medium)
        .background(Palette.warningTint, in: RoundedRectangle(cornerRadius: Radius.field + 2, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("proposals.stale")
    }

    private func choiceButton(_ title: String, choice: TemplateProposalReview.Choice, row: TemplateProposalReview.Row) -> some View {
        let isChosen = viewModel.choice(for: row.change.path, in: proposal) == choice
        return Button {
            viewModel.setChoice(choice, for: row.change.path, in: proposal)
        } label: {
            Text(title)
                .font(.caption)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, 3)
                .foregroundStyle(isChosen ? Palette.accentText : Palette.label)
                .background(isChosen ? Palette.accentTint : Palette.fill2, in: Capsule())
                .overlay(Capsule().strokeBorder(isChosen ? Palette.accent : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}
