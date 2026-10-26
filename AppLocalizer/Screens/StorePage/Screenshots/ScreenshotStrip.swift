//
//  ScreenshotStrip.swift
//  AppLocalizer
//

import SwiftUI

/// One locale and device size: numbered placeholders shaped like the
/// device and "6 screenshots", or a red "Missing" / "Uses English (U.S.)".
struct ScreenshotStrip: View {
    let device: ScreenshotDevice
    let status: ScreenshotStatus

    var body: some View {
        switch status {
        case let .present(count):
            HStack(spacing: Spacing.xxSmall) {
                ForEach(1...count, id: \.self) { index in
                    Text(verbatim: "\(index)")
                        .font(.system(size: 9).monospacedDigit())
                        .foregroundStyle(Palette.label3)
                        .padding(.bottom, 2)
                        .frame(width: thumbnailWidth, height: 38, alignment: .bottom)
                        .background(Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.badge, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.badge, style: .continuous)
                                .strokeBorder(Palette.separator2, lineWidth: 0.5)
                        )
                }
                Text(status.title)
                    .font(.caption2)
                    .foregroundStyle(Palette.label2)
                    .padding(.leading, Spacing.xxSmall)
            }
            .accessibilityElement(children: .ignore)
        case .missing, .usesPrimary:
            Pill(text: status.title, style: .danger)
        }
    }

    private var thumbnailWidth: CGFloat {
        switch device {
        case .iPhone: 22
        case .iPad: 30
        case .mac: 44
        }
    }
}
