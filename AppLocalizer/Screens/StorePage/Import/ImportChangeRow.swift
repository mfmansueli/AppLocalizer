//
//  ImportChangeRow.swift
//  AppLocalizer
//

import SwiftUI

/// One change in the import diff: a checkbox, the locale and field, and
/// the old text struck through over the new one.
struct ImportChangeRow: View {
    let change: ListingImportChange
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Toggle(isOn: Binding { change.isSelected } set: { _ in onToggle() }) {
                EmptyView()
            }
            .toggleStyle(.checkbox)
            .labelsHidden()
            .accessibilityLabel(Text("Include \(change.key.locale.name) \(change.key.field.title)"))
            .accessibilityIdentifier("storePage.import.change.\(change.key.id)")
            VStack(alignment: .leading, spacing: 2) {
                Text(change.key.locale.name)
                    .fontWeight(.semibold)
                Text(change.key.field.title)
                    .foregroundStyle(Palette.label2)
            }
            .frame(width: 170, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(change.oldValue.isEmpty ? String(localized: "Empty") : change.oldValue)
                    .strikethrough()
                    .foregroundStyle(Palette.label3)
                    .lineLimit(2)
                Text(change.newValue)
                    .lineLimit(3)
                    .environment(\.layoutDirection, change.key.locale.isRTL && !change.key.field.isURL ? .rightToLeft : .leftToRight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.callout)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }
}
