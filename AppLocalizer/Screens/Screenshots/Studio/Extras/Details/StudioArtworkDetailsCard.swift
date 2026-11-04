//
//  StudioArtworkDetailsCard.swift
//  AppLocalizer
//

import SwiftUI

/// "Header and search" under the App Store preview: for the new set's
/// artwork in the shown language, each image's size and format, its text,
/// its checks and whether it's new or on App Store Connect, with View
/// Larger; then the same across every language.
struct StudioArtworkDetailsCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let details: StudioArtworkDetails

    var body: some View {
        Card {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Text("Header and search")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(details.languageName)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("studio.artwork.details.language")
                Spacer(minLength: Spacing.medium)
                Text(details.languagesSummary)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("studio.artwork.details.languages")
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(details.rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { Divider() }
                    rowView(row)
                }
            }
            Text(StudioArtworkDetails.shownOn)
                .font(.caption)
                .foregroundStyle(Palette.label2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("studio.artwork.details")
    }

    private func rowView(_ row: StudioArtworkDetails.Row) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .fontWeight(.semibold)
                Text(row.format)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("studio.artwork.details.\(row.kind.rawValue).format")
            }
            .frame(width: 250, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.text)
                    .accessibilityIdentifier("studio.artwork.details.\(row.kind.rawValue).text")
                Label(row.checks, systemImage: Self.symbol(row.checksTone))
                    .foregroundStyle(Self.color(row.checksTone))
                    .accessibilityIdentifier("studio.artwork.details.\(row.kind.rawValue).checks")
                Text(row.status)
                    .foregroundStyle(Self.color(row.statusTone))
                    .accessibilityIdentifier("studio.artwork.details.\(row.kind.rawValue).status")
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("View Larger") { studio.openArtwork(at: row.viewerIndex) }
                .controlSize(.small)
                .disabled(!row.isMade)
                .accessibilityIdentifier("studio.artwork.details.\(row.kind.rawValue).view")
        }
        .font(.callout)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("studio.artwork.details.\(row.kind.rawValue)")
    }

    static func color(_ tone: StudioArtworkDetails.Tone) -> Color {
        switch tone {
        case .neutral: Palette.label2
        case .accent: Palette.accent
        case .positive: Palette.positive
        case .warning: Palette.warning
        case .danger: Palette.danger
        }
    }

    static func symbol(_ tone: StudioArtworkDetails.Tone) -> String {
        switch tone {
        case .positive: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .danger: "xmark.octagon.fill"
        case .neutral, .accent: "minus.circle"
        }
    }
}
