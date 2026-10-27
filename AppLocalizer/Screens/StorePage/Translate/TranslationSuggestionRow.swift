//
//  TranslationSuggestionRow.swift
//  AppLocalizer
//

import SwiftUI

/// One suggestion: the locale and field, the current text struck through
/// (if there is one) over the suggested text, and Reject / Accept, or the
/// decision with Undo.
struct TranslationSuggestionRow: View {
    let suggestion: TranslationSuggestion
    let onAccept: () -> Void
    let onReject: () -> Void
    let onUndo: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.key.locale.name)
                    .font(.callout.weight(.semibold))
                Text(suggestion.key.field.title)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .frame(width: 170, alignment: .leading)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                if !suggestion.currentText.isEmpty {
                    Text(suggestion.currentText)
                        .font(.caption)
                        .strikethrough()
                        .foregroundStyle(Palette.label3)
                }
                Text(suggestion.suggestedText)
                    .font(.callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.layoutDirection, suggestion.isRightToLeft ? .rightToLeft : .leftToRight)
                if let message = suggestion.validation.message {
                    InlineMessage(text: message, systemImage: "exclamationmark.triangle", tint: Palette.danger)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            actions
                .frame(width: 170, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, 10)
        .opacity(suggestion.decision == .rejected ? 0.5 : 1)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(suggestion.key.locale.name), \(suggestion.key.field.title)"))
        .accessibilityIdentifier("storePage.suggestion.\(suggestion.key.id)")
    }

    private var actions: some View {
        HStack(spacing: Spacing.xSmall) {
            switch suggestion.decision {
            case .pending:
                Button("Reject", action: onReject)
                Button("Accept", action: onAccept)
            case .accepted:
                Pill(text: String(localized: "Accepted"), systemImage: "checkmark", style: .machineTranslated)
                Button("Undo", action: onUndo)
                    .buttonStyle(.link)
            case .rejected:
                Pill(text: String(localized: "Rejected"), style: .outline)
                Button("Undo", action: onUndo)
                    .buttonStyle(.link)
            }
        }
        .controlSize(.small)
    }
}
