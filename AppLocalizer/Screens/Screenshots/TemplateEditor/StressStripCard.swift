//
//  StressStripCard.swift
//  AppLocalizer
//

import SwiftUI

/// One stress locale: the render, its name and role, the fit meter and
/// label, and the check that fails, if one does.
struct StressStripCard: View {
    let entry: StressStripEntry
    let capture: CGImage?
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            SlotPreviewImage(preview: entry.preview, capture: capture, width: width)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(entry.locale.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                Text(entry.roleText)
                    .font(.caption2)
                    .foregroundStyle(Palette.label2)
                FitMeter(value: FitMeterValue(fit: entry.preview.fit))
                    .padding(.vertical, 2)
                Text(entry.preview.fit.label)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(labelColor)
                    .layoutPriority(1)
                if let failure = entry.preview.firstFailure?.shortReason {
                    Text(failure)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.danger)
                }
            }
        }
        .padding(Spacing.small)
        .frame(width: width + 16, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Radius.card).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(entry.locale.name), \(entry.roleText), \(entry.preview.fit.label)"))
        .accessibilityIdentifier("screenshots.template.strip.\(entry.locale.code)")
    }

    private var labelColor: Color {
        switch entry.preview.fit.tone {
        case .overflows: Palette.danger
        case .shrinks: Palette.warning
        case .fits, .empty: Palette.label2
        }
    }
}
