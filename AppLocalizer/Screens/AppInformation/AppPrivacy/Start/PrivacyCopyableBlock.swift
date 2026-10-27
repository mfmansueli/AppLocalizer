//
//  PrivacyCopyableBlock.swift
//  AppLocalizer
//

import SwiftUI

/// Monospaced text to paste somewhere else, selectable, with its Copy
/// button beside it.
struct PrivacyCopyableBlock: View {
    let text: String
    let buttonTitle: String
    let isProminent: Bool
    let id: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Text(text)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.small + 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
                .accessibilityIdentifier("appInformation.appPrivacy.\(id).text")
            button
                .controlSize(.small)
                .accessibilityIdentifier("appInformation.appPrivacy.\(id).copy")
        }
    }

    @ViewBuilder
    private var button: some View {
        if isProminent {
            Button(buttonTitle, action: action).buttonStyle(.borderedProminent)
        } else {
            Button(buttonTitle, action: action)
        }
    }
}
