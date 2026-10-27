//
//  ScreenshotReviewFooter.swift
//  AppLocalizer
//

import SwiftUI

/// The review footer once images are in review: Discard All; the requests,
/// minutes and share of the hourly limit; Cancel, Push n Selected and Push
/// n Images (Push n Changes when text changes go too).
struct ScreenshotReviewFooter: View {
    let viewModel: ReviewPushViewModel
    let onDiscardAll: () -> Void
    let onCancel: () -> Void
    let onPushSelected: () -> Void
    let onPushAll: () -> Void

    var body: some View {
        HStack(spacing: Spacing.small) {
            Button("Discard All", role: .destructive, action: onDiscardAll)
                .buttonStyle(.borderless)
                .foregroundStyle(Palette.danger)
                .disabled(viewModel.visibleChanges.isEmpty && viewModel.visibleImages.isEmpty)
                .accessibilityIdentifier("review.discardAll")
            Spacer()
            ForEach(viewModel.optionFootnotes, id: \.self) { footnote in
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("review.optionFootnote")
            }
            if viewModel.allPushCount > 0 {
                Text(viewModel.imagesEstimateText)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .monospacedDigit()
                    .lineLimit(1)
                    .accessibilityIdentifier("review.estimate")
            }
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)
            Button(String(localized: "Push \(viewModel.selectedPushCount) Selected"), action: onPushSelected)
                .disabled(viewModel.selectedPushCount == 0)
                .accessibilityIdentifier("review.pushSelected")
            Button(pushAllTitle, action: onPushAll)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.allPushCount == 0)
                .accessibilityIdentifier("review.pushAll")
        }
        .buttonBorderShape(.capsule)
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }

    /// "Push 40 Images", or "Push 66 Changes" with text changes too.
    private var pushAllTitle: String {
        let count = viewModel.allPushCount
        if viewModel.pushableChanges.isEmpty {
            return count == 1 ? String(localized: "Push 1 Image") : String(localized: "Push \(count) Images")
        }
        return count == 1 ? String(localized: "Push 1 Change") : String(localized: "Push \(count) Changes")
    }
}
