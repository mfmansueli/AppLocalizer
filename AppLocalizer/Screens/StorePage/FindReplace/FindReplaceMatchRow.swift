//
//  FindReplaceMatchRow.swift
//  AppLocalizer
//

import SwiftUI

/// A match in Find and Replace: "English (U.S.) · Description" over the
/// text around it, the match highlighted. Says so when the replacement
/// would go over the field's limit.
struct FindReplaceMatchRow: View {
    let match: FindReplaceMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Spacing.xSmall) {
                Text(match.key.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                if match.occurrenceCount > 1 {
                    Pill(text: String(localized: "\(match.occurrenceCount) times"))
                }
                if let label = match.validation.accessibilityLabel, match.validation.isBlocking {
                    Pill(text: String(localized: "Over the limit"), style: .danger)
                        .accessibilityLabel(Text(label))
                }
            }
            Text(highlighted)
                .font(.callout)
                .lineLimit(1)
                .environment(\.layoutDirection, match.key.locale.isRTL ? .rightToLeft : .leftToRight)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("storePage.find.match.\(match.key.id)")
    }

    private var highlighted: AttributedString {
        let snippet = match.snippet
        var prefix = AttributedString(snippet.prefix)
        prefix.foregroundColor = Palette.label2
        var hit = AttributedString(snippet.match)
        hit.backgroundColor = Palette.warningTint
        var suffix = AttributedString(snippet.suffix)
        suffix.foregroundColor = Palette.label2
        return prefix + hit + suffix
    }
}
