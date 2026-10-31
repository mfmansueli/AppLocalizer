//
//  AutopilotLogView.swift
//  AppLocalizer
//

import SwiftUI

/// The assistant's last steps: commands dimmed, arrivals in the label
/// color, problems in red.
struct AutopilotLogView: View {
    let entries: [AutopilotLogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if entries.isEmpty {
                Text("Nothing yet").foregroundStyle(Palette.label2)
            }
            ForEach(entries) { entry in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                    Text(entry.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).second(.twoDigits)))
                        .foregroundStyle(Palette.label3)
                    Text(entry.text)
                        .foregroundStyle(color(entry.kind))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .font(.system(.caption, design: .monospaced))
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("autopilot.log")
    }

    private func color(_ kind: AutopilotLogEntry.Kind) -> Color {
        switch kind {
        case .command: Palette.label2
        case .event: Palette.label
        case .problem: Palette.danger
        }
    }
}
