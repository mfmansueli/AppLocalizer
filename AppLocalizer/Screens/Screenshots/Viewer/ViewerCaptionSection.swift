//
//  ViewerCaptionSection.swift
//  AppLocalizer
//

import SwiftUI

/// The caption as written, aligned the way the locale reads, with its fit
/// meter and where it came from.
struct ViewerCaptionSection: View {
    let cell: ScreenshotCell
    let isRightToLeft: Bool

    var body: some View {
        ViewerSection(title: String(localized: "Caption")) {
            if let caption = cell.caption, !caption.isEmpty {
                VStack(alignment: alignment, spacing: 2) {
                    Text(caption.headline)
                        .font(.callout)
                    if let subhead = caption.visibleSubhead {
                        Text(subhead)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                    }
                }
                .multilineTextAlignment(isRightToLeft ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: isRightToLeft ? .trailing : .leading)
                .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
                .textSelection(.enabled)
                if let fit = cell.layout?.headline {
                    FitMeter(value: FitMeterValue(fit: fit))
                        .padding(.top, Spacing.xxSmall)
                    Text(fit.label)
                        .font(.caption.weight(fit.fits ? .regular : .medium))
                        .foregroundStyle(fit.fits ? Palette.label2 : Palette.danger)
                        .accessibilityIdentifier("screenshots.viewer.fit")
                }
                Text(caption.provenance.title)
                    .font(.caption)
                    .foregroundStyle(Palette.label3)
            } else {
                Text("No caption for this slot yet.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
        }
    }

    private var alignment: HorizontalAlignment { isRightToLeft ? .trailing : .leading }
}
