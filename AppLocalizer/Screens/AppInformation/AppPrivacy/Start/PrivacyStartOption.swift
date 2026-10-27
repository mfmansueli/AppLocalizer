//
//  PrivacyStartOption.swift
//  AppLocalizer
//

import SwiftUI

/// One of the other ways to start, as a tile with a title and a line.
struct PrivacyStartOption: View {
    let title: String
    let detail: String
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.label)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(detail))
        .accessibilityIdentifier("appInformation.appPrivacy.start.\(id)")
    }
}
