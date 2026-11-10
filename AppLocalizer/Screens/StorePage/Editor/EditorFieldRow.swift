//
//  EditorFieldRow.swift
//  AppLocalizer
//

import SwiftUI

/// One field in the editor, as a card: its title and where it appears on the
/// App Store, tags and counter, the text, the inline error, for keywords the
/// token view, then the field's suggestion (its purple edge goes round the
/// card) or where its pending value came from.
struct EditorFieldRow: View {
    let viewModel: StorePageViewModel
    let field: ListingField
    let locale: StoreLocale

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            titleLine
            EditorFieldInput(
                field: field,
                locale: locale,
                text: binding,
                isEditable: viewModel.canEdit(field),
                isBlocked: validation.isBlocking,
                isFocusRequested: viewModel.focusRequest == ListingFieldKey(locale, field)
            ) {
                viewModel.focusRequest = nil
            }
            if let message = validation.message {
                InlineMessage(text: message, systemImage: "exclamationmark.triangle", tint: Palette.danger)
                    .font(.caption)
                    .accessibilityIdentifier("storePage.fieldError.\(field.rawValue)")
            }
            if field == .keywords, !viewModel.value(.keywords, in: locale).isEmpty {
                KeywordTokensView(
                    analysis: viewModel.keywordAnalysis(in: locale),
                    isEditable: viewModel.canEdit(.keywords),
                    onRemove: { viewModel.removeKeyword(at: $0, in: locale) },
                    onOptimize: { viewModel.optimizeKeywords(in: locale) }
                )
            }
            if let provenance = viewModel.provenance(field, in: locale) {
                SuggestionProvenanceLine(provenance: provenance, currentValue: viewModel.value(field, in: locale)) {
                    viewModel.undoSuggestion(field, in: locale)
                }
            }
            if let suggestion {
                FieldSuggestionCard(
                    fieldTitle: field.title,
                    suggestion: suggestion,
                    current: viewModel.value(field, in: locale),
                    suggested: suggestion.value,
                    meta: viewModel.suggestionMeta(suggestion),
                    onDismiss: { viewModel.dismissSuggestion(suggestion) },
                    onUseAndEdit: { viewModel.useAndEditSuggestion(suggestion) },
                    onAccept: { viewModel.acceptSuggestion(suggestion) }
                )
            } else if viewModel.isComing(field, in: locale), let run = viewModel.suggestionRun {
                SuggestionComingPlaceholder(client: run.client)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, 10)
        .background(Palette.raised, in: shape)
        .overlay {
            shape.strokeBorder(
                suggestion == nil ? Palette.separator : Palette.machineTranslatedMark.opacity(0.55),
                lineWidth: suggestion == nil ? 0.5 : 1
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.field.\(field.rawValue)")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    private var suggestion: FieldSuggestion? { viewModel.shownSuggestion(field, in: locale) }
    private var draft: ListingFieldDraft { viewModel.draft(field, in: locale) }
    private var validation: ListingFieldValidation { viewModel.validation(of: field, in: locale) }

    private var binding: Binding<String> {
        Binding {
            viewModel.value(field, in: locale)
        } set: { value in
            viewModel.edit(field, in: locale, to: value)
        }
    }

    private var titleLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(field.title)
                .font(.subheadline.weight(.semibold))
                .fixedSize()
            Text(field.whereShown(version: viewModel.content?.version.versionString))
                .font(.caption2)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            if draft.isMachineTranslated {
                Pill(text: String(localized: "Machine-translated"), systemImage: "sparkle", style: .machineTranslated)
                    .fixedSize()
                    .accessibilityLabel(Text("Machine-translated, not reviewed"))
                Button("Mark Reviewed") {
                    viewModel.markReviewed(field, in: locale)
                }
                .buttonStyle(.link)
                .font(.caption)
                .fixedSize()
                .accessibilityIdentifier("storePage.markReviewed.\(field.rawValue)")
            }
            if let client = draft.proposedBy {
                SourceTag(source: .assistant(client: client))
                    .fixedSize()
            } else if let source = draft.suggestionSource {
                SourceTag(source: source)
                    .fixedSize()
            }
            if draft.isPending {
                HStack(spacing: Spacing.xxSmall) {
                    UnsavedDot(size: 6)
                    Text("Not pushed")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(Palette.accentText)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Palette.accentTint, in: Capsule())
                .fixedSize()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Not pushed"))
                .accessibilityIdentifier("storePage.notPushed.\(field.rawValue)")
            }
            counter
        }
    }

    @ViewBuilder
    private var counter: some View {
        if let limit = field.limit {
            let counter = ListingFieldCounter(viewModel.value(field, in: locale), limit: limit)
            Group {
                if counter.isOverLimit {
                    Pill(text: counter.text, style: .danger)
                } else {
                    Text(counter.text)
                        .font(.caption2.monospaced())
                        .foregroundStyle(Palette.label2)
                }
            }
            .fixedSize()
            // One element: a pill is a stack of views, which would leave
            // the label on none of them.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(counter.accessibilityLabel))
            .accessibilityIdentifier("storePage.counter.\(field.rawValue)")
        }
    }
}
