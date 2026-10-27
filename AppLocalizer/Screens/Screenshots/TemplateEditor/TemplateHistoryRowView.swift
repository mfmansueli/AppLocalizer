//
//  TemplateHistoryRowView.swift
//  AppLocalizer
//

import SwiftUI

/// One version in the history popover.
struct TemplateHistoryRowView: View {
    let row: TemplateEditorViewModel.HistoryRow
    let onRestore: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Pill(text: "v\(row.number)")
            VStack(alignment: .leading, spacing: 3) {
                Text(row.note)
                    .font(.callout)
                    .layoutPriority(1)
                Text(row.detail)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                if let assistant = row.assistant {
                    HStack(spacing: Spacing.xxSmall) {
                        MonogramTag(client: assistant)
                        Text("Proposed by \(assistant) · accepted by you")
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if row.isCurrent {
                Text("Current")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            if row.canRestore {
                Button("Restore This Version", action: onRestore)
                    .controlSize(.small)
                    .accessibilityIdentifier("screenshots.template.restore.\(row.number)")
            }
        }
        .padding(Spacing.small)
        .background(row.isCurrent ? Palette.fill1 : .clear, in: RoundedRectangle(cornerRadius: Radius.field))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.template.version.\(row.number)")
    }
}
