//
//  RenderStatusView.swift
//  AppLocalizer
//

import SwiftUI

/// The bar's trailing status: "Rendering 22 of 60" with a bar while the
/// queue works, otherwise "40 not pushed · 2 checks failed · both display
/// types".
struct RenderStatusView: View {
    let progress: ScreenshotRenderProgress?
    let status: String

    var body: some View {
        Group {
            if let progress {
                HStack(spacing: Spacing.xSmall) {
                    ProgressView()
                        .controlSize(.mini)
                    Text(progress.title)
                        .monospacedDigit()
                    ProgressView(value: progress.fraction)
                        .progressViewStyle(.linear)
                        .frame(width: 90)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(progress.title))
            } else {
                Text(status)
                    .foregroundStyle(Palette.label2)
            }
        }
        .font(.caption)
        .lineLimit(1)
        .accessibilityIdentifier("screenshots.status")
    }
}
