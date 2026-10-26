//
//  PrivacyEvidenceCard.swift
//  AppLocalizer
//

import SwiftUI

/// One piece of evidence: its kind, where it is, and the excerpt.
struct PrivacyEvidenceCard: View {
    let evidence: PrivacyEvidence

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(evidence.kind.title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Palette.label2)
            Text(evidence.reference)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            if let excerpt = evidence.excerpt, !excerpt.isEmpty {
                Text(excerpt)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(Spacing.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.badge, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.badge, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
            }
        }
        .padding(Spacing.small + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
