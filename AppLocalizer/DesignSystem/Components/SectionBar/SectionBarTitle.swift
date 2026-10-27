//
//  SectionBarTitle.swift
//  AppLocalizer
//

import SwiftUI

/// The leading side of a `SectionBar`: an icon tile, what's being edited and
/// a detail line, plus an up-down chevron when it opens a picker (wrap it in
/// a `Button` or `Menu`).
struct SectionBarTitle: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    var showsChevron = false

    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: systemImage)
                .font(.system(size: 13))
                .foregroundStyle(Palette.label2)
                .frame(width: 28, height: 28)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Palette.label)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            if showsChevron {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SectionBarTitle(
        systemImage: "doc",
        title: "Version 1.4 · Prepare for Submission",
        subtitle: "Name, Subtitle and Privacy URL are app-level",
        showsChevron: true
    )
    .padding()
}
