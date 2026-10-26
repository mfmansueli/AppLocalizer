//
//  SettingsRowLabel.swift
//  AppLocalizer
//

import SwiftUI

/// A settings row's title with an optional one-line explanation under it,
/// as the label of a `Picker`, `Toggle` or `LabeledContent`.
struct SettingsRowLabel: View {
    let title: LocalizedStringKey
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    Form {
        Toggle(isOn: .constant(true)) {
            SettingsRowLabel(title: "Discount only", caption: "Never above Apple’s equalized price")
        }
    }
    .formStyle(.grouped)
    .frame(width: 500, height: 120)
}
