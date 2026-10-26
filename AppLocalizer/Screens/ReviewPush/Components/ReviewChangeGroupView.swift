//
//  ReviewChangeGroupView.swift
//  AppLocalizer
//

import SwiftUI

/// A heading ("Subscription Pricing · Lumen Plus Annual · 164 changes"), the
/// price schedule line with Edit…, and the group's rows.
struct ReviewChangeGroupView: View {
    let group: ReviewChangeGroup
    let viewModel: ReviewPushViewModel
    var onEditSchedule: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(group.title)
                    .font(.headline)
                Spacer()
                Text(group.changes.count == 1 ? "1 change" : "\(group.changes.count) changes")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small + 2)
            .background(Palette.fill1)
            if let note = group.note {
                Divider()
                HStack(spacing: Spacing.small) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Palette.label2)
                        .accessibilityHidden(true)
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                    Spacer()
                    if let onEditSchedule {
                        Button("Edit…", action: onEditSchedule)
                            .buttonStyle(.link)
                            .font(.callout)
                            .accessibilityIdentifier("review.editSchedule")
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
            }
            ForEach(group.changes) { change in
                Divider()
                ReviewChangeRow(
                    change: change,
                    isSelected: viewModel.isSelected(change.id),
                    onToggle: { viewModel.toggle(change.id) },
                    onDiscard: { viewModel.discard(change.id) },
                    onKeepMine: { viewModel.keepMine(change.id) },
                    onUseRemote: { viewModel.useRemote(change.id) },
                    onPickAlternative: { viewModel.resolveAlternative(change.id, keepAlternative: $0) },
                    onSetOption: { viewModel.setOption(change.id, isOn: $0) }
                )
            }
        }
        .background(Palette.raised)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
    }
}
