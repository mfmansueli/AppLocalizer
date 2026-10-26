//
//  AssistantLogRow.swift
//  AppLocalizer
//

import SwiftUI

/// One line of the activity log: time, tool, what it was about (and why it
/// was refused), which client, and the outcome.
struct AssistantLogRow: View {
    let entry: MCPLogEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(entry.date.formatted(date: .omitted, time: .standard))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Palette.label2)
                .frame(width: 64, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                // Above what it was about: tool names run long
                // ("propose_accessibility_declaration").
                Text(entry.tool)
                    .font(.caption.monospaced())
                if !entry.target.isEmpty {
                    Text(entry.target)
                        .font(.caption)
                        .lineLimit(1)
                }
                if let reason = entry.reason {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(Palette.warning)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(entry.client)
                    .font(.caption2)
                    .foregroundStyle(Palette.label3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Pill(text: entry.outcome.title, style: entry.outcome.pillStyle)
        }
        .accessibilityElement(children: .combine)
    }
}
