//
//  PrivacyChecklistStepRow.swift
//  AppLocalizer
//

import SwiftUI

/// "1 Data collection · Yes, we collect data from this app", its tick and
/// Copy.
struct PrivacyChecklistStepRow: View {
    let step: PrivacyChecklistStep
    @Binding var isChecked: Bool
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Toggle(isOn: $isChecked) {
                Text("\(step.number) \(step.title)")
            }
            .toggleStyle(.checkbox)
            .labelsHidden()
            .accessibilityLabel(Text("\(step.number) \(step.title)"))
            .accessibilityIdentifier("appInformation.appPrivacy.step.\(step.id).check")
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                HStack(spacing: Spacing.xxSmall) {
                    Text(step.number)
                        .foregroundStyle(Palette.label2)
                        .monospacedDigit()
                    Text(step.title)
                        .fontWeight(.semibold)
                }
                .font(.callout)
                Text(step.body)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if step.canCopy {
                Button(isCopied ? String(localized: "Copied") : String(localized: "Copy"), action: onCopy)
                    .controlSize(.small)
                    .accessibilityLabel(Text("Copy step \(step.number)"))
                    .accessibilityIdentifier("appInformation.appPrivacy.step.\(step.id).copy")
            }
        }
        .padding(.vertical, Spacing.small + 2)
        .padding(.trailing, Spacing.medium)
        .padding(.leading, step.isTypeStep ? Spacing.xxxLarge + Spacing.xxSmall : Spacing.medium)
        .background(step.isTypeStep ? Palette.fill1 : Palette.raised)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.step.\(step.id)")
    }
}
