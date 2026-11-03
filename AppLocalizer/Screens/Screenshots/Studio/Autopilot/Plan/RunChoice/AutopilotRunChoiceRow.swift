//
//  AutopilotRunChoiceRow.swift
//  AppLocalizer
//

import SwiftUI

/// One row of "What this run makes": its checkbox with what it makes (or
/// what stays live when it's off), a cell per device, and its languages.
/// An off row is dimmed but stays readable.
struct AutopilotRunChoiceRow<Cells: View, Languages: View>: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool
    let identifier: String
    @ViewBuilder let cells: () -> Cells
    @ViewBuilder let languages: () -> Languages

    var body: some View {
        GridRow(alignment: .center) {
            Toggle(isOn: $isOn) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).fontWeight(.medium)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.checkbox)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier(identifier)
            cells()
                .opacity(isOn ? 1 : 0.62)
            languages()
                .opacity(isOn ? 1 : 0.62)
                .frame(width: AutopilotRunChoiceCard.languagesWidth, alignment: .leading)
        }
        .padding(.vertical, Spacing.xSmall)
    }
}
