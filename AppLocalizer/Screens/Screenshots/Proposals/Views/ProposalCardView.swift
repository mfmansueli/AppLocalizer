//
//  ProposalCardView.swift
//  AppLocalizer
//

import SwiftUI

/// A proposal in the sheet's list: who and when, its title, what it
/// changes, and where it stands.
struct ProposalCardView: View {
    let proposal: ScreenshotProposal
    let subtitle: String
    let status: ProposalCardStatus
    let isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack(spacing: Spacing.xSmall) {
                    SourceTag(source: proposal.source)
                    Text(proposal.timeText())
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Spacing.xSmall)
                    Pill(text: status.title, style: status.style)
                        .accessibilityIdentifier("proposals.card.status")
                }
                Text(proposal.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.label)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.medium)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.field + 2, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.field + 2, style: .continuous)
                    .strokeBorder(isSelected ? Palette.accent : Palette.separator, lineWidth: isSelected ? 2 : 0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("proposals.card.\(proposal.id)")
    }
}
