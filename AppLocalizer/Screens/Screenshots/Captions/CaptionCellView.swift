//
//  CaptionCellView.swift
//  AppLocalizer
//

import SwiftUI

/// One caption: the headline on two lines, the subhead on hero slots, the
/// fit meter and its label, and the MT, CC and edited tags. A missing
/// caption offers "Write caption" or "Missing".
struct CaptionCellView: View {
    let cell: CaptionsCell
    let localeName: String
    let isRightToLeft: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Group {
                if let caption = cell.caption {
                    filled(caption)
                } else {
                    Label(cell.missingTitle, systemImage: "plus")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
            .background(background, in: RoundedRectangle(cornerRadius: Radius.field))
            .overlay(border)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(cell.accessibilityText(localeName: localeName)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("screenshots.captions.cell.\(cell.key.locale).\(cell.key.slot)")
    }

    private func filled(_ caption: ScreenshotCaption) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(caption.headline)
                .font(.callout.weight(.medium))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: isRightToLeft ? .trailing : .leading)
                .multilineTextAlignment(isRightToLeft ? .trailing : .leading)
            if cell.showsSubhead, let subhead = caption.visibleSubhead {
                Text(subhead)
                    .font(.caption2)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: isRightToLeft ? .trailing : .leading)
            }
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
                if cell.isEdited {
                    UnsavedDot(size: 6)
                        .accessibilityLabel(Text("Edited"))
                }
            }
        }
    }

    private var labelColor: Color {
        switch cell.fit?.tone {
        case .overflows: Palette.danger
        case .shrinks: Palette.warning
        default: Palette.label2
        }
    }

    private var background: Color {
        isSelected ? Palette.accentTint : .clear
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
