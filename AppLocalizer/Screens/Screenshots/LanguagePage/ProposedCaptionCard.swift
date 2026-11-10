//
//  ProposedCaptionCard.swift
//  AppLocalizer
//

import SwiftUI

/// A caption an assistant suggested, under the screenshots: "Screenshot 2 ·
/// caption", who suggested it and why, the caption now and suggested, and
/// Dismiss, Use and Edit, Accept.
struct ProposedCaptionCard: View {
    let caption: ProposedCaption
    /// What the caption reads now; "" reads "Empty".
    let current: String
    let isRightToLeft: Bool
    let onDismiss: () -> Void
    let onUseAndEdit: () -> Void
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.xSmall) {
                Text(caption.title)
                    .font(.headline)
                Spacer(minLength: Spacing.small)
                Image(systemName: "sparkle")
                    .imageScale(.small)
                    .foregroundStyle(Palette.machineTranslated)
                    .accessibilityHidden(true)
                Text("Suggested")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.machineTranslated)
                SuggestionSourceTag(source: caption.source)
            }
            if !caption.reason.isEmpty {
                Text(caption.reason)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .top, spacing: Spacing.medium) {
                text(String(localized: "NOW"), current.isEmpty ? String(localized: "Empty") : current, isEmpty: current.isEmpty)
                text(String(localized: "SUGGESTED"), caption.item.headline, isSuggested: true)
            }
            HStack(spacing: Spacing.small) {
                Spacer()
                Button("Dismiss", action: onDismiss)
                    .accessibilityIdentifier("screenshots.page.caption.dismiss")
                Button("Use and Edit", action: onUseAndEdit)
                    .accessibilityIdentifier("screenshots.page.caption.useAndEdit")
                Button("Accept", action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("screenshots.page.caption.accept")
            }
            .controlSize(.small)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.machineTranslatedTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.page.caption.\(caption.slot)")
    }

    private func text(_ label: String, _ value: String, isEmpty: Bool = false, isSuggested: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isSuggested ? AnyShapeStyle(Palette.machineTranslated) : AnyShapeStyle(Palette.label2))
            Text(value)
                .font(.callout)
                .foregroundStyle(isEmpty ? Palette.label3 : Palette.label)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.layoutDirection, isRightToLeft && !isEmpty ? .rightToLeft : .leftToRight)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
