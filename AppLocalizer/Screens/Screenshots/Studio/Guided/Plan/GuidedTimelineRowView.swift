//
//  GuidedTimelineRowView.swift
//  AppLocalizer
//

import SwiftUI

/// A line of the guided plan: who does it ("CC Claude Code", or You),
/// what and how, anything under it (the capture line's screens), and how
/// long it takes or which stop it is.
struct GuidedTimelineRowView<Accessory: View>: View {
    let row: GuidedTimelineRow
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            who
                .frame(width: 104, alignment: .leading)
            VStack(alignment: .leading, spacing: Spacing.tiny) {
                Text(row.title)
                    .font(.callout.weight(.semibold))
                    .accessibilityIdentifier("autopilot.guided.plan.row.\(row.kind.rawValue).title")
                Text(row.detail)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("autopilot.guided.plan.row.\(row.kind.rawValue).detail")
                accessory()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(row.time)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.label2)
                .accessibilityIdentifier("autopilot.guided.plan.row.\(row.kind.rawValue).time")
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.plan.row.\(row.kind.rawValue)")
    }

    @ViewBuilder
    private var who: some View {
        if row.isYours {
            Pill(text: row.who.name, style: .machineTranslated)
                .frame(width: 92)
                .accessibilityLabel(Text("Your step"))
        } else {
            HStack(spacing: Spacing.xxSmall) {
                Text(row.who.initials)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Palette.label2)
                    .frame(width: 20, height: 20)
                    .background(Palette.fill2, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .accessibilityHidden(true)
                Text(row.who.name)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(2)
            }
        }
    }
}

extension GuidedTimelineRowView where Accessory == EmptyView {
    init(row: GuidedTimelineRow) {
        self.init(row: row) { EmptyView() }
    }
}
