//
//  NewLanguageSheetRow.swift
//  AppLocalizer
//

import SwiftUI

/// One language in the languages sheet: a checkbox, "Polish pl", "Added"
/// once it is, the catalog's numbers, and whether its page is drafted.
struct NewLanguageSheetRow: View {
    let row: NewLanguageRow
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Toggle(isOn: Binding(get: { isOn }, set: { _ in onToggle() })) {
                EmptyView()
            }
            .toggleStyle(.checkbox)
            .labelsHidden()
            .disabled(row.isAdded)
            .accessibilityLabel(Text("Add \(row.locale.name)"))
            .accessibilityIdentifier("storePage.languagesSheet.toggle.\(row.locale.code)")
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xSmall) {
                    Text(row.locale.name)
                        .font(.callout.weight(.semibold))
                    Text(row.locale.code)
                        .font(.caption.monospaced())
                        .foregroundStyle(Palette.label2)
                    if row.isAdded {
                        Pill(text: String(localized: "Added"), style: .accent)
                            .accessibilityIdentifier("storePage.languagesSheet.added.\(row.locale.code)")
                    }
                }
                if !row.evidence.isEmpty {
                    Text(row.evidence)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                Text(row.drafted)
                    .font(.caption)
                    .accessibilityIdentifier("storePage.languagesSheet.drafted.\(row.locale.code)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { if !row.isAdded { onToggle() } }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.languagesSheet.row.\(row.locale.code)")
    }
}
