//
//  ArtworkTextCellView.swift
//  AppLocalizer
//

import SwiftUI

/// A Search results or Header cell: the text, its fit meter on the
/// artwork, its fit and word count, and its tags.
struct ArtworkTextCellView: View {
    let cell: ArtworkTextCell
    let localeName: String
    let isRightToLeft: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Group {
                if let text = cell.text {
                    filled(text)
                } else {
                    Label(cell.emptyTitle, systemImage: cell.role.isOptional ? "minus" : "plus")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
            .background(isSelected ? Palette.accentTint : .clear, in: RoundedRectangle(cornerRadius: Radius.field))
            .overlay(border)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(cell.accessibilityText(localeName: localeName)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("screenshots.captions.artwork.\(cell.key.locale).\(cell.role.rawValue)")
    }

    private func filled(_ text: ScreenshotCaption) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text.headline)
                .font(.callout.weight(.medium))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: isRightToLeft ? .trailing : .leading)
                .multilineTextAlignment(isRightToLeft ? .trailing : .leading)
            Spacer(minLength: Spacing.xxSmall)
            if let fit = cell.fit {
                FitMeter(value: FitMeterValue(fit: fit))
                    .padding(.vertical, 2)
            }
            HStack(spacing: Spacing.xxSmall) {
                Text(cell.fitLabel)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if cell.isMachineTranslated {
                    Pill(text: String(localized: "MT"), style: .machineTranslated)
                        .accessibilityLabel(Text("Machine-translated"))
                }
                if let assistant = cell.assistant {
                    MonogramTag(client: assistant)
                }
            }
        }
    }

    private var labelColor: Color {
        if cell.fit?.tone == .overflows { return Palette.danger }
        if cell.fit?.tone == .shrinks || cell.count?.isTooLong == true { return Palette.warning }
        return Palette.label2
    }

    @ViewBuilder
    private var border: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: Radius.field).strokeBorder(Palette.accent, lineWidth: 1)
        } else if cell.isMissing {
            RoundedRectangle(cornerRadius: Radius.field).strokeBorder(Palette.separator2, lineWidth: 0.5)
        }
    }
}
