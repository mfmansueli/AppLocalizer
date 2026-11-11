//
//  PaywallDoneView.swift
//  AppLocalizer
//

import SwiftUI

/// After buying: what's unlocked, when the trial ends, and a button that
/// finishes what the person started.
struct PaywallDoneView: View {
    let model: PaywallModel
    let onClose: (_ continues: Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 34))
                .foregroundStyle(Palette.positive)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(model.doneTitle)
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("paywall.done.title")
                Text(model.doneSubtitle)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("paywall.done.subtitle")
            }
            Text("Unlocked")
                .font(.headline)
                .padding(.top, Spacing.xSmall)
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                ForEach(ProFeature.allCases) { feature in
                    Label(feature.title, systemImage: "checkmark")
                        .font(.callout)
                }
            }
            Spacer(minLength: Spacing.small)
            HStack(spacing: Spacing.small) {
                Spacer()
                Button(model.closeTitle) { onClose(false) }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("paywall.done.close")
                if let title = model.continueTitle {
                    Button(title) { onClose(true) }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .accessibilityIdentifier("paywall.done.continue")
                }
            }
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("paywall.done")
    }
}
