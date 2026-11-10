//
//  OverviewWaitingCard.swift
//  AppLocalizer
//

import SwiftUI

/// "65 suggestions waiting for you": one row per section with what it
/// changes, where its suggestions are, the purple count or Reviewed, and
/// Review (or Open).
struct OverviewWaitingCard: View {
    let appName: String
    let rows: [OverviewWaitingSection]
    let onOpen: (AppWorkspaceSection) -> Void

    private var total: Int { rows.reduce(0) { $0 + $1.count } }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Palette.suggestionBadge, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("overview.waiting.title")
            }
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { Divider() }
                    rowView(row)
                }
            }
            .padding(.top, Spacing.xxSmall)
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("overview.waiting")
    }

    private var title: String {
        switch total {
        case 0: String(localized: "Nothing waiting for you")
        case 1: String(localized: "1 suggestion waiting for you")
        default: String(localized: "\(total) suggestions waiting for you")
        }
    }

    private var subtitle: String {
        total > 0
            ? String(localized: "From Claude Code and AppLocalizer’s own checks. Review them where they apply; nothing reaches the App Store until you push.")
            : String(localized: "Everything is reviewed. Push when you’re ready.")
    }

    private func rowView(_ row: OverviewWaitingSection) -> some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: row.systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Self.tint(for: row.section), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                    Text(row.title)
                        .font(.headline)
                    Text(row.what(appName: appName))
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                }
                Text(row.detail)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if row.count > 0 {
                SuggestionBadge(count: row.count)
            } else {
                Pill(text: String(localized: "✓ Reviewed"), style: .outline)
                    .fixedSize()
            }
            Button(row.buttonTitle) { onOpen(row.section) }
                .buttonBorderShape(.capsule)
                .accessibilityLabel(Text(row.accessibilityText))
                .accessibilityIdentifier("overview.waiting.open.\(row.section.rawValue)")
        }
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("overview.waiting.row.\(row.section.rawValue)")
    }

    static func tint(for section: AppWorkspaceSection) -> Color {
        switch section {
        case .overview: Palette.accent
        case .storePage: Palette.sectionStorePage
        case .screenshots: Palette.sectionScreenshots
        case .subscriptionPricing: Palette.sectionPricing
        case .appInformation: Palette.sectionAppInformation
        }
    }
}
