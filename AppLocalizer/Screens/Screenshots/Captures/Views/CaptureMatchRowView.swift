//
//  CaptureMatchRowView.swift
//  AppLocalizer
//

import SwiftUI

/// One file in the matching table: where it goes, or, tinted yellow, why
/// it needs you and the choice to make.
struct CaptureMatchRowView: View {
    let row: CaptureMatchRow
    var onChoose: (CaptureChoice) -> Void

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Text(row.path)
                .font(.caption.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let issue = row.issue {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(issue.message)
                        .font(.caption)
                        .foregroundStyle(Palette.warning)
                        .fixedSize(horizontal: false, vertical: true)
                    Picker(issue.message, selection: choice) {
                        ForEach(row.options) { option in
                            Text(option.title).tag(Optional(option.choice))
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)
                    .fixedSize()
                    .accessibilityIdentifier("captures.row.choice")
                }
                .frame(width: CaptureMatchColumns.locale + CaptureMatchColumns.display + CaptureMatchColumns.slot + Spacing.medium * 2, alignment: .leading)
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(Palette.warningMark)
                    .frame(width: CaptureMatchColumns.status)
                    .accessibilityLabel(Text("Needs you"))
            } else if let placement = row.placement {
                Text(StoreLocaleCatalog.locale(code: placement.locale)?.name ?? placement.locale)
                    .frame(width: CaptureMatchColumns.locale, alignment: .leading)
                Text(placement.displayType.title)
                    .foregroundStyle(Palette.label2)
                    .frame(width: CaptureMatchColumns.display, alignment: .leading)
                Text(verbatim: "\(placement.slot + 1)")
                    .monospacedDigit()
                    .frame(width: CaptureMatchColumns.slot, alignment: .leading)
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .frame(width: CaptureMatchColumns.status)
                    .accessibilityLabel(Text("Matched"))
            }
        }
        .font(.callout)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, row.needsYou ? Spacing.small : Spacing.xSmall)
        .background(row.needsYou ? Palette.warningTint : Color.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(row.needsYou ? "captures.row.needsYou" : "captures.row.matched")
    }

    private var choice: Binding<CaptureChoice?> {
        Binding {
            row.choice
        } set: { newValue in
            if let newValue { onChoose(newValue) }
        }
    }
}
