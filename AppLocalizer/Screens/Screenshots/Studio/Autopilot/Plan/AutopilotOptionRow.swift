//
//  AutopilotOptionRow.swift
//  AppLocalizer
//

import SwiftUI

/// A checkbox with a line under it; locked ones show what always happens.
struct AutopilotOptionRow: View {
    let title: String
    let detail: String?
    @Binding var isOn: Bool
    var isLocked = false

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(.checkbox)
        .disabled(isLocked)
    }
}
