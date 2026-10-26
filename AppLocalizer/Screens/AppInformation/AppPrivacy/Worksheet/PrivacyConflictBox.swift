//
//  PrivacyConflictBox.swift
//  AppLocalizer
//

import SwiftUI

/// "Claude Code’s answer differs from yours. Pick one.": Keep yours, or
/// use the assistant's, each with its answer.
struct PrivacyConflictBox: View {
    let yours: PrivacyAnswer
    let theirs: PrivacySuggestion
    let onKeepYours: () -> Void
    let onUseTheirs: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("**\(theirs.client)’s answer differs from yours.** Pick one.")
                .font(.caption)
            FlowLayout(spacing: Spacing.xSmall) {
                Button(String(localized: "Keep yours · \(yours.summary)"), action: onKeepYours)
                    .accessibilityIdentifier("appInformation.appPrivacy.conflict.keepYours")
                Button(String(localized: "Use \(theirs.client)’s · \(theirs.answer.summary)"), action: onUseTheirs)
                    .accessibilityIdentifier("appInformation.appPrivacy.conflict.useTheirs")
            }
            .controlSize(.small)
        }
        .padding(Spacing.small + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}
