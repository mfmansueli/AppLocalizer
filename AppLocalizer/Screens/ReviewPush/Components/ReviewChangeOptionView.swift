//
//  ReviewChangeOptionView.swift
//  AppLocalizer
//

import SwiftUI

/// The switch under a review row whose change has a `ChangeOption`, e.g.
/// "Publish to the App Store", with the line saying what on or off means,
/// or why it can't be turned on.
struct ReviewChangeOptionView: View {
    let changeID: PendingChange.ID
    let option: ChangeOption
    let onSet: @MainActor (Bool) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.medium) {
            Toggle(isOn: Binding(get: { option.isEffective }, set: onSet)) {
                Text(option.title)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
            .disabled(!option.isEnabled)
            .accessibilityLabel(Text(option.title))
            .accessibilityHint(Text(option.note))
            .accessibilityIdentifier("review.option.\(changeID)")
            VStack(alignment: .leading, spacing: 1) {
                Text(option.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(option.isEnabled ? Palette.label : Palette.label2)
                Text(option.note)
                    .font(.caption2)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityHidden(true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.small + 2)
        .padding(.vertical, Spacing.xSmall + 1)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    VStack {
        ReviewChangeOptionView(
            changeID: "a",
            option: ChangeOption(
                title: "Publish to the App Store",
                isOn: true,
                onNote: "Goes on the product page as soon as it's pushed. It can take up to 24 hours to show everywhere.",
                offNote: "Saved in App Store Connect as a draft; nothing changes on the product page.",
                requests: [],
                progressTitle: "Publishing…",
                doneTitle: "Published",
                offDoneTitle: "Saved as a draft"
            ),
            onSet: { _ in }
        )
        ReviewChangeOptionView(
            changeID: "b",
            option: ChangeOption(
                title: "Publish to the App Store",
                isOn: false,
                onNote: "",
                offNote: "",
                disabledReason: "Apple Vision Pro has no live version yet, so this is saved as a draft. Publish it after 1.4 is released.",
                requests: [],
                progressTitle: "Publishing…",
                doneTitle: "Published",
                offDoneTitle: "Saved as a draft"
            ),
            onSet: { _ in }
        )
    }
    .padding()
    .frame(width: 700)
}
