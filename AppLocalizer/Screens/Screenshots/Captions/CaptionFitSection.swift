//
//  CaptionFitSection.swift
//  AppLocalizer
//

import SwiftUI

/// The large fit meter with its zones, the label, and the line count and
/// size in u.
struct CaptionFitSection: View {
    let model: CaptionsViewModel

    var body: some View {
        let fit = model.editorPreview?.fit
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Fit")
                .font(.callout.weight(.semibold))
            if let fit {
                FitMeter(value: FitMeterValue(fit: fit), height: 7)
                    .padding(.vertical, 2)
            }
            HStack {
                Text("Fits at full size")
                Spacer()
                Text("Shrinks")
                Spacer()
                Text("Overflows")
            }
            .font(.caption2)
            .foregroundStyle(Palette.label3)
            if let fit, !fit.isEmpty {
                Text(fit.label)
                    .font(.callout.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(color(fit.tone))
                    .accessibilityIdentifier("screenshots.captions.editor.fitLabel")
            }
            Text(model.fitDetail)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.label2)
                .accessibilityIdentifier("screenshots.captions.editor.fitDetail")
        }
        .accessibilityElement(children: .contain)
    }

    private func color(_ tone: FitTone) -> Color {
        switch tone {
        case .overflows: Palette.danger
        case .shrinks: Palette.warning
        case .fits, .empty: Palette.label
        }
    }
}
