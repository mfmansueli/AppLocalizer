//
//  ScreenshotRestoreLocaleRow.swift
//  AppLocalizer
//

import SwiftUI

/// A radio row in the restore sheet's locale list: the flag, the name and
/// what was kept.
struct ScreenshotRestoreLocaleRow: View {
    let choice: ScreenshotRestoreChoice
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.small) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Palette.accent : Palette.label3)
                    .accessibilityHidden(true)
                FlagTile(regionCode: choice.locale.regionCode)
                VStack(alignment: .leading, spacing: 1) {
                    Text(choice.locale.name)
                        .font(.callout)
                        .lineLimit(1)
                    Text(choice.note)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(isSelected ? Palette.fill2 : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(choice.locale.name), \(choice.note)"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("restore.locale.\(choice.locale.code)")
    }
}
