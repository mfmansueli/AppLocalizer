//
//  LocaleScopeTable.swift
//  AppLocalizer
//

import SwiftUI

/// The Locale Scope sheet's list: a checkbox, the locale, its captions,
/// whose interface its captures show, and what's live there now.
struct LocaleScopeTable: View {
    @Bindable var viewModel: ScreenshotsViewModel

    var body: some View {
        let primaryName = viewModel.context.primaryLocale.name
        Table(viewModel.scopeRows) {
            TableColumn("") { row in
                Toggle(isOn: included(row)) {
                    Text(row.locale.name)
                }
                .toggleStyle(.checkbox)
                .labelsHidden()
                .disabled(row.isPrimary)
                .accessibilityLabel(Text("Localize \(row.locale.name)"))
                .accessibilityIdentifier("screenshots.scope.toggle.\(row.locale.code)")
            }
            .width(24)
            TableColumn(String(localized: "Locale")) { row in
                LocaleLabel(locale: row.locale, isPrimary: row.isPrimary)
            }
            .width(min: 180, ideal: 240)
            TableColumn(String(localized: "Captions")) { row in
                Text(row.captionsTitle)
                    .foregroundStyle(row.captionCount == 0 ? Palette.label3 : Palette.label)
            }
            .width(min: 80, ideal: 110)
            TableColumn(String(localized: "Captures")) { row in
                Text(row.capturesTitle)
                    .foregroundStyle(row.hasOwnInterface ? Palette.label : Palette.label3)
            }
            .width(min: 100, ideal: 120)
            TableColumn(String(localized: "Live now")) { row in
                liveCell(row, primaryName: primaryName)
            }
            .width(min: 120, ideal: 150)
        }
        .tableStyle(.inset)
        .alternatingRowBackgrounds(.disabled)
        .accessibilityIdentifier("screenshots.scope.table")
    }

    @ViewBuilder
    private func liveCell(_ row: LocaleScopeRow, primaryName: String) -> some View {
        if row.isPinned {
            HStack(spacing: Spacing.xSmall) {
                Text("Restored")
                Button("Use Template Again") {
                    Task { await viewModel.useTemplateAgain(row.locale.code) }
                }
                .controlSize(.small)
                .accessibilityIdentifier("screenshots.scope.useTemplate.\(row.locale.code)")
            }
        } else {
            Text(row.liveTitle(primaryName: primaryName))
        }
    }

    private func included(_ row: LocaleScopeRow) -> Binding<Bool> {
        Binding {
            row.isIncluded
        } set: { isOn in
            viewModel.setScope(row.locale.code, included: isOn)
        }
    }
}
