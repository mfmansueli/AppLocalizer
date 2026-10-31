//
//  DesignKindCard.swift
//  AppLocalizer
//

import SwiftUI

/// One design source to choose: a radio, its name and what it reads.
struct DesignKindCard: View {
    let kind: DesignProjectKind
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.small) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Palette.label3)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xSmall) {
                        Text(kind.title).font(.headline)
                        if kind == .claudeDesign { Pill(text: String(localized: "Recommended"), style: .accent) }
                    }
                    Text(kind.summary)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(isSelected ? Palette.accentTint : Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Palette.separator, lineWidth: isSelected ? 1.5 : 0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("designProject.kind.\(kind.rawValue)")
    }
}
