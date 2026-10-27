//
//  PrivacyLabelGroupCard.swift
//  AppLocalizer
//

import SwiftUI

/// One of the label's groups, e.g. "Data Linked to You", with each
/// category and its types.
struct PrivacyLabelGroupCard: View {
    let group: PrivacyLabelPreview.Group

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(group.kind.title, systemImage: group.kind.systemImage)
                .font(.callout.weight(.semibold))
            Text(group.kind.subtitle)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(group.lines) { line in
                VStack(alignment: .leading, spacing: 0) {
                    Text(line.category.name)
                        .font(.caption.weight(.semibold))
                    Text(line.typeNames)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, Spacing.xxSmall)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.labelPreview.\(group.kind.rawValue)")
    }
}
