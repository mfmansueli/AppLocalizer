//
//  GuidedLiveTimelineView.swift
//  AppLocalizer
//

import SwiftUI

/// Making it's steps: the plan's timeline as the run goes. Done lines are
/// checked, the one Autopilot works on now turns and says "Now", the
/// person's stops say they're theirs, and the rest wait in gray.
struct GuidedLiveTimelineView: View {
    let rows: [GuidedTimelineRow]
    let states: [GuidedTimelineRow.Kind: GuidedLiveTimeline.State]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(rows) { row in
                line(row, state: states[row.kind] ?? .upcoming)
                if row.id != rows.last?.id { Divider().padding(.leading, 46) }
            }
        }
        .padding(.vertical, Spacing.xxSmall)
        .modifier(GuidedSelectableCard(padding: 0))
        .animation(.easeInOut(duration: 0.35), value: states)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Autopilot’s steps"))
        .accessibilityIdentifier("autopilot.guided.making.steps")
    }

    private func line(_ row: GuidedTimelineRow, state: GuidedLiveTimeline.State) -> some View {
        HStack(alignment: .center, spacing: Spacing.small) {
            mark(row, state: state)
                .frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(row.title)
                    .font(.callout.weight(state == .running || state == .current ? .semibold : .regular))
                    .foregroundStyle(state == .upcoming ? Palette.label2 : Palette.label)
                    .lineLimit(2)
                Text(row.who.name)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing(row, state: state)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.xSmall)
        .background(state == .running ? Palette.accentTint : Color.clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(row.title), \(row.who.name)"))
        .accessibilityValue(Text(stateName(state)))
        .accessibilityIdentifier("autopilot.guided.making.step.\(row.kind.rawValue)")
    }

    @ViewBuilder
    private func mark(_ row: GuidedTimelineRow, state: GuidedLiveTimeline.State) -> some View {
        switch state {
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 17))
                .foregroundStyle(Palette.accent)
        case .running:
            ZStack {
                GuidedWorkingRing(size: 26)
                badge(row, active: true)
            }
        case .current, .upcoming:
            badge(row, active: state == .current)
                .padding(3)
                .overlay(Circle().strokeBorder(state == .current ? Palette.accent : Color.clear, lineWidth: 1.5))
        }
    }

    /// "CC", "AL", or a person for the person's stops.
    private func badge(_ row: GuidedTimelineRow, active: Bool) -> some View {
        Group {
            if row.isYours {
                Image(systemName: "person.fill").font(.system(size: 9, weight: .semibold))
            } else {
                Text(row.who.initials).font(.system(size: 8, weight: .bold))
            }
        }
        .foregroundStyle(active ? Palette.accent : Palette.label2)
        .frame(width: 18, height: 18)
        .background(active ? Palette.accentTint : Palette.fill2, in: Circle())
    }

    @ViewBuilder
    private func trailing(_ row: GuidedTimelineRow, state: GuidedLiveTimeline.State) -> some View {
        switch state {
        case .running:
            Text("Now")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.accentText)
        case .current:
            Text(row.isYours ? String(localized: "Your turn") : String(localized: "Needs you"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.accentText)
        case .done:
            EmptyView()
        case .upcoming:
            Text(row.time)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.label2)
        }
    }

    private func stateName(_ state: GuidedLiveTimeline.State) -> String {
        switch state {
        case .done: String(localized: "done")
        case .running: String(localized: "running now")
        case .current: String(localized: "waiting for you")
        case .upcoming: String(localized: "to come")
        }
    }
}
