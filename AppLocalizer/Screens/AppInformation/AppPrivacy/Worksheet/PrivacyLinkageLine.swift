//
//  PrivacyLinkageLine.swift
//  AppLocalizer
//

import SwiftUI

/// "Linked to the user · Yes   Used for tracking · No", each a menu.
struct PrivacyLinkageLine: View {
    let type: PrivacyDataType
    let answer: PrivacyAnswer
    let viewModel: AppPrivacyViewModel

    var body: some View {
        HStack(spacing: Spacing.large) {
            menu(String(localized: "Linked to the user"), isTracking: false)
            menu(String(localized: "Used for tracking"), isTracking: true)
        }
        .font(.caption)
    }

    private func menu(_ title: String, isTracking: Bool) -> some View {
        let selection = Binding(
            get: { isTracking ? answer.tracking : answer.linked },
            set: { value in
                if isTracking {
                    viewModel.setTracking(type, value)
                } else {
                    viewModel.setLinked(type, value)
                }
            }
        )
        return HStack(spacing: Spacing.xxSmall) {
            Text("\(title) ·")
                .foregroundStyle(Palette.label2)
            Picker(title, selection: selection) {
                Text("Yes").tag(true)
                Text("No").tag(false)
            }
            .pickerStyle(.menu)
            .buttonStyle(.borderless)
            .labelsHidden()
            .fixedSize()
            .controlSize(.small)
            .accessibilityLabel(Text(title))
            .accessibilityIdentifier("appInformation.appPrivacy.type.\(type.rawValue).\(isTracking ? "tracking" : "linked")")
        }
    }
}
