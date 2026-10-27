//
//  ScreenshotPushProgressRow.swift
//  AppLocalizer
//

import SwiftUI

/// One image in a running push: its state, a tiny thumbnail, "Arabic ·
/// iPhone · 1 Today" with the reason in red when it failed, and the step
/// on the right: Queued, Reserving…, Uploading 64% with a bar,
/// Committing…, Done · Apple is processing, Failed, Cancelled.
struct ScreenshotPushProgressRow: View {
    let item: ScreenshotUploadItem
    let image: CGImage?

    var body: some View {
        HStack(spacing: 10) {
            statusIcon
                .frame(width: 18)
            ScreenshotThumbnail(image: image, width: item.plan.cell.displayType.isTablet ? 24 : 18, aspect: ScreenshotThumbnail.aspect(of: item.plan))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let failure = item.status.failureText {
                    Text(failure)
                        .font(.caption)
                        .foregroundStyle(Palette.danger)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let note = item.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.status.stepTitle)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .monospacedDigit()
                    .lineLimit(1)
                if let fraction = item.status.uploadFraction {
                    ProgressView(value: fraction)
                        .progressViewStyle(.linear)
                        .controlSize(.mini)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: 200, alignment: .leading)
        }
        .font(.callout)
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
        .accessibilityIdentifier("push.shots.row.\(ScreenshotReviewItemCard.identifier(item.plan))")
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .queued, .cancelled, .notSent:
            Image(systemName: "circle")
                .foregroundStyle(Palette.label3)
        case .keepingCopy, .reserving, .uploading, .committing:
            ProgressView()
                .controlSize(.mini)
        case .done:
            Image(systemName: "checkmark")
                .foregroundStyle(Palette.label2)
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Palette.dangerMark)
        }
    }

    private var accessibilityText: String {
        [item.title, item.status.stepTitle, item.status.failureText ?? item.note].compactMap(\.self).joined(separator: ", ")
    }
}
