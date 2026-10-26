//
//  PrivacyPurposeToggles.swift
//  AppLocalizer
//

import SwiftUI

/// Apple's six purposes as toggle buttons, wrapping to the row's width.
struct PrivacyPurposeToggles: View {
    let answer: PrivacyAnswer
    let onToggle: @MainActor (PrivacyPurpose) -> Void

    var body: some View {
        FlowLayout(spacing: Spacing.xSmall) {
            ForEach(PrivacyPurpose.allCases) { purpose in
                Toggle(purpose.shortTitle, isOn: Binding(get: { answer.purposes.contains(purpose) }, set: { _ in onToggle(purpose) }))
                    .toggleStyle(.button)
                    .controlSize(.small)
                    .help(purpose.title)
                    .accessibilityLabel(Text(purpose.title))
                    .accessibilityIdentifier("appInformation.appPrivacy.purpose.\(purpose.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Purposes"))
    }
}
