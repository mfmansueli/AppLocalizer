//
//  CustomIndexImportSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Previews a CSV before it becomes the custom index: what matched, what
/// didn't, and what the rest of the territories fall back to.
struct CustomIndexImportSheet: View {
    let preview: CustomIndexPreview
    let territoryCount: Int
    let onCancel: () -> Void
    let onImport: () -> Void

    var body: some View {
        let result = preview.result
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text("Import a custom index").font(.title3.weight(.semibold))
                    Text(subtitle)
                        .font(.caption.monospaced())
                        .foregroundStyle(Palette.label2)
                }
                rowsTable(result)
                if !result.unmatched.isEmpty {
                    unmatchedNote(result.unmatched)
                }
                ForEach(result.errors, id: \.self) { error in
                    InlineMessage.warning(error.message)
                }
                Text("The other \(territoryCount - result.rows.count) territories use the next source in your fallback chain.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
            .padding(Spacing.xLarge)
            Divider()
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button(importTitle(result.rows.count), action: onImport)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(result.isEmpty)
                    .accessibilityIdentifier("pricing.import.confirm")
            }
            .buttonBorderShape(.capsule)
            .padding(.horizontal, Spacing.xLarge)
            .padding(.vertical, Spacing.medium)
        }
        .frame(width: 540)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.importSheet")
    }

    private var subtitle: String {
        let kind = preview.result.kind == .factor ? String(localized: "territory code → factor") : String(localized: "territory code → local price")
        return String(localized: "\(preview.fileName) · \(preview.lineCount) rows · \(kind)")
    }

    private func importTitle(_ count: Int) -> String {
        count == 1 ? String(localized: "Import 1 Territory") : String(localized: "Import \(count) Territories")
    }

    private func rowsTable(_ result: CustomIndexImport) -> some View {
        let visible = result.rows.prefix(CustomIndexPreview.visibleRowCount)
        return VStack(spacing: 0) {
            Grid(alignment: .leading, horizontalSpacing: Spacing.large, verticalSpacing: 0) {
                GridRow {
                    Text("Code")
                    Text("Territory").gridColumnAlignment(.leading)
                    Text("Factor").gridColumnAlignment(.trailing)
                }
                .font(.callout.weight(.medium))
                .foregroundStyle(Palette.label2)
                .frame(height: Metrics.tableHeaderHeight)
                ForEach(visible, id: \.self) { row in
                    Divider().gridCellColumns(3)
                    GridRow {
                        Text(row.code).font(.callout.monospaced())
                        Text(row.territory.name).frame(maxWidth: .infinity, alignment: .leading)
                        Text(row.factor.fixed(2)).monospacedDigit()
                    }
                    .frame(height: Metrics.tableRowHeight)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, Spacing.small)
            if result.rows.count > visible.count {
                Divider()
                Text("+ \(result.rows.count - visible.count) more matched rows")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.small)
                    .frame(height: Metrics.tableRowHeight)
            }
        }
        .background(Palette.content, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay { RoundedRectangle(cornerRadius: Radius.card).strokeBorder(Palette.separator, lineWidth: 0.5) }
    }

    private func unmatchedNote(_ unmatched: [CustomIndexImport.UnmatchedCode]) -> some View {
        let codes = unmatched.map { code in
            code.suggestion.map { String(localized: "\(code.code) (did you mean \($0.alpha2)?)") } ?? code.code
        }
        let list = codes.formatted(.list(type: .and))
        let title = unmatched.count == 1
            ? String(localized: "1 code didn’t match a territory:")
            : String(localized: "\(unmatched.count) codes didn’t match a territory:")
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.warningMark)
                .accessibilityHidden(true)
            Text("\(Text(title).bold()) \(list). They’re skipped.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.warningTint, in: RoundedRectangle(cornerRadius: Radius.banner))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("pricing.import.unmatched")
    }
}
