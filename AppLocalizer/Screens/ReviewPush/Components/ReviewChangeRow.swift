//
//  ReviewChangeRow.swift
//  AppLocalizer
//

import SwiftUI

/// One pending change: checkbox, flag and title, old → new with the price
/// change, who made it and a discard button. Conflicts and blocks show
/// underneath; blocked changes can't be checked. A change with an option
/// (e.g. "Publish to the App Store") shows its switch underneath, and its
/// old and new values on two lines.
struct ReviewChangeRow: View {
    let change: PendingChange
    let isSelected: Bool
    let onToggle: () -> Void
    let onDiscard: () -> Void
    let onKeepMine: () -> Void
    let onUseRemote: () -> Void
    let onPickAlternative: (_ keepAlternative: Bool) -> Void
    var onSetOption: @MainActor (Bool) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Toggle(isOn: Binding(get: { isSelected && !change.isBlocked }, set: { _ in onToggle() })) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .labelsHidden()
                .disabled(change.isBlocked)
                .accessibilityLabel(Text("Select \(change.title)"))
                if let region = change.flagRegion {
                    FlagTile(regionCode: region)
                }
                Text(change.title)
                    .lineLimit(1)
                    .frame(width: 170, alignment: .leading)
                values
                Spacer(minLength: Spacing.small)
                SourceTag(source: change.source)
                Button(action: onDiscard) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .help("Discard this change")
                .accessibilityLabel(Text("Discard \(change.title)"))
                .accessibilityIdentifier("review.discard.\(change.id)")
            }
            if let conflict = change.remoteConflict {
                RemoteConflictView(mine: change.newValue, conflict: conflict, onKeepMine: onKeepMine, onUseRemote: onUseRemote)
            } else if let alternative = change.alternative {
                AlternativeConflictView(yours: change.newValue, alternative: alternative, onPick: onPickAlternative)
            } else if let reason = change.blockedReason {
                Label(reason, systemImage: "exclamationmark.octagon.fill")
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
                    .padding(.leading, 26)
            }
            if let option = change.option {
                ReviewChangeOptionView(changeID: change.id, option: option, onSet: onSetOption)
                    .padding(.leading, 26)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.row.\(change.id)")
    }

    @ViewBuilder
    private var values: some View {
        if change.option != nil {
            stackedValues
        } else {
            inlineValues
        }
    }

    /// Old over "→ new", for values too long to share a line.
    private var stackedValues: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(change.oldValue.isEmpty ? String(localized: "Empty") : change.oldValue)
                .foregroundStyle(Palette.label2)
            Text("\(Image(systemName: "arrow.right")) \(change.newValue.isEmpty ? String(localized: "Empty") : change.newValue)")
        }
        .lineLimit(1)
        .font(.callout)
    }

    private var inlineValues: some View {
        HStack(spacing: Spacing.xSmall) {
            Text(change.oldValue.isEmpty ? String(localized: "Empty") : change.oldValue)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .layoutPriority(-1)
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(Palette.label3)
                .accessibilityLabel(Text("to"))
            Text(change.newValue.isEmpty ? String(localized: "Empty") : change.newValue)
                .fontWeight(.semibold)
                .lineLimit(1)
            if let delta = change.deltaPercent {
                DeltaPill(percent: delta)
            }
        }
        .monospacedDigit()
    }
}

#Preview {
    ReviewChangeRow(
        change: PendingChange(
            id: "price.annual.BRA",
            appID: "1",
            section: .subscriptionPricing,
            group: "Subscription Pricing · Lumen Plus Annual",
            title: "Brazil",
            flagRegion: "BR",
            oldValue: "R$ 219,90",
            newValue: "R$ 109,90",
            deltaPercent: -50,
            source: .suggestion,
            requests: []
        ),
        isSelected: false,
        onToggle: {},
        onDiscard: {},
        onKeepMine: {},
        onUseRemote: {},
        onPickAlternative: { _ in }
    )
    .frame(width: 760)
}
