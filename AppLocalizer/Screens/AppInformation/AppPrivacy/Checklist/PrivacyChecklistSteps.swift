//
//  PrivacyChecklistSteps.swift
//  AppLocalizer
//

import SwiftUI

/// The steps in one box, a data type's steps indented under step 2.
struct PrivacyChecklistSteps: View {
    let viewModel: AppPrivacyViewModel

    var body: some View {
        let steps = viewModel.steps
        VStack(spacing: 0) {
            ForEach(steps) { step in
                PrivacyChecklistStepRow(
                    step: step,
                    isChecked: Binding(get: { viewModel.isChecked(step) }, set: { viewModel.setChecked(step, $0) }),
                    isCopied: viewModel.copiedStepID == step.id
                ) {
                    viewModel.copyStep(step)
                }
                if step.id != steps.last?.id {
                    Divider()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.checklist.steps")
    }
}
