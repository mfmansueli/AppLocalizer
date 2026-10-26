//
//  TranslationSuggestionsView.swift
//  AppLocalizer
//

import SwiftUI

/// After a batch: every suggestion against the current text, accepted or
/// rejected one by one or all at once. Done turns the accepted ones into
/// pending changes, tagged machine-translated.
struct TranslationSuggestionsView: View {
    let viewModel: StorePageViewModel

    private var translation: TranslateMissingViewModel { viewModel.translation }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            header
            Divider()
            if let failure = translation.failureSummary {
                InlineMessage.warning(failure)
                    .font(.caption)
                    .padding(.horizontal, Spacing.large)
                    .padding(.vertical, Spacing.xSmall)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("storePage.suggestions.failures")
                Divider()
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(translation.review?.suggestions ?? []) { suggestion in
                        TranslationSuggestionRow(
                            suggestion: suggestion,
                            onAccept: { translation.accept(suggestion.id) },
                            onReject: { translation.reject(suggestion.id) },
                            onUndo: { translation.undo(suggestion.id) }
                        )
                        Divider()
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.suggestions")
    }

    private var header: some View {
        let count = translation.review?.suggestions.count ?? 0
        return HStack(spacing: Spacing.small) {
            Text(count == 1
                ? "1 suggestion from \(translation.runProvider.shortTitle)"
                : "\(count) suggestions from \(translation.runProvider.shortTitle)")
                .font(.headline)
            Text(translation.review?.statusLine ?? "")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.label2)
                .accessibilityIdentifier("storePage.suggestions.status")
            Spacer(minLength: Spacing.small)
            Button("Reject All") { translation.rejectAll() }
                .accessibilityIdentifier("storePage.suggestions.rejectAll")
            Button("Accept All") { translation.acceptAll() }
                .accessibilityIdentifier("storePage.suggestions.acceptAll")
            Button("Done") { viewModel.finishSuggestions() }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("storePage.suggestions.done")
        }
        .controlSize(.small)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }
}
