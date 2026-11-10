//
//  SectionHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The top of a section: a colored icon, the section's name, one sentence
/// about what it changes on the App Store, and its controls on the right.
struct SectionHeader<Trailing: View>: View {
    let systemImage: String
    let tint: Color
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: Spacing.small)
            HStack(spacing: Spacing.small) {
                trailing()
            }
            .fixedSize()
        }
        .frame(minHeight: 40)
    }
}

#Preview {
    SectionHeader(
        systemImage: "doc.text",
        tint: Palette.sectionStorePage,
        title: "Store Page",
        subtitle: "The words on Lumen’s App Store page and in search, in every language."
    ) {
        Button("Ask Claude Code…") {}
    }
    .padding()
    .frame(width: 720)
}
