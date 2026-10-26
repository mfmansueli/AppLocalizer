//
//  ReviewFooter.swift
//  AppLocalizer
//

import SwiftUI

/// Discard All on the left; what options will do ("2 declarations publish
/// immediately when pushed"), the request estimate, Cancel, Push Selected
/// and Push n Changes on the right.
struct ReviewFooter: View {
    let viewModel: ReviewPushViewModel
    let onDiscardAll: () -> Void
    let onCancel: () -> Void
    let onPush: ([PendingChange]) -> Void

    var body: some View {
        HStack(spacing: Spacing.small) {
            Button("Discard All", role: .destructive, action: onDiscardAll)
                .buttonStyle(.borderless)
                .foregroundStyle(Palette.danger)
                .disabled(viewModel.visibleChanges.isEmpty)
                .accessibilityIdentifier("review.discardAll")
            Spacer()
            ForEach(viewModel.optionFootnotes, id: \.self) { footnote in
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .monospacedDigit()
                    .accessibilityIdentifier("review.optionFootnote")
            }
            if !viewModel.pushableChanges.isEmpty {
                Text(viewModel.estimate.text)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .monospacedDigit()
            }
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)
            Button("Push Selected") { onPush(viewModel.selectedPushableChanges) }
                .disabled(viewModel.selectedPushableChanges.isEmpty)
                .accessibilityIdentifier("review.pushSelected")
            Button(pushAllTitle) { onPush(viewModel.pushableChanges) }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.pushableChanges.isEmpty)
                .accessibilityIdentifier("review.pushAll")
        }
        .buttonBorderShape(.capsule)
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }

    private var pushAllTitle: String {
        let count = viewModel.pushableChanges.count
        return count == 1 ? String(localized: "Push 1 Change") : String(localized: "Push \(count) Changes")
    }
}
