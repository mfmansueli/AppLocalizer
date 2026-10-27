//
//  TemplateHistoryPopover.swift
//  AppLocalizer
//

import SwiftUI

/// The versions with their date, author and note, newest first. Restore
/// This Version makes a new version from an old one.
struct TemplateHistoryPopover: View {
    let model: TemplateEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text("Template history")
                .textCase(.uppercase)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.label2)
                .padding(.horizontal, Spacing.small)
                .padding(.bottom, Spacing.xxSmall)
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(model.historyRows) { row in
                        TemplateHistoryRowView(row: row) {
                            Task { await model.restore(row.number) }
                        }
                    }
                }
            }
            .frame(maxHeight: 360)
            .fixedSize(horizontal: false, vertical: true)
            Text("Restoring makes a new version from the old one, so nothing is lost.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .padding(.horizontal, Spacing.small)
                .padding(.top, Spacing.xxSmall)
        }
        .padding(Spacing.small)
        .frame(width: 360)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.template.historyPopover")
    }
}
