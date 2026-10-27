//
//  CaptionEditorTags.swift
//  AppLocalizer
//

import SwiftUI

/// Machine-translated with Mark Reviewed, who proposed it, and "Suggest a
/// Shorter Version" with its suggestion.
struct CaptionEditorTags: View {
    let model: CaptionsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if model.isMachineTranslated {
                HStack(spacing: Spacing.small) {
                    Pill(text: String(localized: "Machine-translated"), style: .machineTranslated)
                    Spacer()
                    Button("Mark Reviewed") {
                        Task { await model.markReviewed() }
                    }
                    .controlSize(.small)
                    .accessibilityIdentifier("screenshots.captions.editor.markReviewed")
                }
            }
            if let note = model.assistantNote {
                HStack(spacing: Spacing.xxSmall) {
                    MonogramTag(client: note.client)
                    Text(note.text)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                .accessibilityElement(children: .combine)
            }
            if model.canSuggestShorter {
                Button("Suggest a Shorter Version") {
                    Task { await model.suggestShorter() }
                }
                .controlSize(.small)
                .accessibilityIdentifier("screenshots.captions.editor.suggest")
            }
            if model.isSuggesting {
                ProgressView()
                    .controlSize(.small)
            }
            if let message = model.suggestionMessage {
                InlineMessage.warning(message)
            }
            if let suggestion = model.suggestion {
                CaptionSuggestionBox(
                    suggestion: suggestion,
                    isRightToLeft: model.isRightToLeft
                ) {
                    Task { await model.useSuggestion() }
                } onKeep: {
                    model.keepMine()
                }
            }
        }
    }
}
