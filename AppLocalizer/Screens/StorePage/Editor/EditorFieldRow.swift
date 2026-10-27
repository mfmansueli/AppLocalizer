//
//  EditorFieldRow.swift
//  AppLocalizer
//

import SwiftUI

/// One field in the editor: its title, level, tags and counter, the primary
/// locale's text on the left and the edited locale's on the right, the
/// inline error, and for keywords the token view underneath.
struct EditorFieldRow: View {
    let viewModel: StorePageViewModel
    let field: ListingField
    let locale: StoreLocale

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            titleLine
            HStack(alignment: .top, spacing: Spacing.medium) {
                primaryValue
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                EditorFieldInput(
                    field: field,
                    locale: locale,
                    text: binding,
                    isEditable: viewModel.canEdit(field),
                    isBlocked: validation.isBlocking
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
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
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.field.\(field.rawValue)")
    }

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
        HStack(spacing: Spacing.small) {
            Text(field.title)
                .font(.headline)
            Pill(text: field.level.badgeTitle(version: viewModel.content?.version.versionString ?? ""), style: .outline)
            if draft.isMachineTranslated {
                Pill(text: String(localized: "Machine-translated"), systemImage: "sparkle", style: .machineTranslated)
                    .accessibilityLabel(Text("Machine-translated, not reviewed"))
                Button("Mark Reviewed") {
                    viewModel.markReviewed(field, in: locale)
                }
                .buttonStyle(.link)
                .font(.caption)
                .accessibilityIdentifier("storePage.markReviewed.\(field.rawValue)")
            }
            if let client = draft.proposedBy {
                SourceTag(source: .assistant(client: client))
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Not pushed"))
                .accessibilityIdentifier("storePage.notPushed.\(field.rawValue)")
            }
            Spacer(minLength: Spacing.small)
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
                        .font(.caption.monospaced())
                        .foregroundStyle(Palette.label2)
                }
            }
            // One element: a pill is a stack of views, which would leave
            // the label on none of them.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(counter.accessibilityLabel))
            .accessibilityIdentifier("storePage.counter.\(field.rawValue)")
        }
    }

    private var primaryValue: some View {
        let primary = viewModel.listing?.primaryLocale ?? .englishUS
        let text = viewModel.value(field, in: primary)
        return ScrollView {
            Text(text.isEmpty ? "—" : text)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, 5)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(minHeight: 24, maxHeight: field.isMultiline ? 150 : 40)
        .fixedSize(horizontal: false, vertical: !field.isMultiline)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .environment(\.layoutDirection, primary.isRTL && !field.isURL ? .rightToLeft : .leftToRight)
        .accessibilityLabel(Text("\(primary.name), \(field.title): \(text)"))
    }
}
