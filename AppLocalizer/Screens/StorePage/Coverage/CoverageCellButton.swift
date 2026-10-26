//
//  CoverageCellButton.swift
//  AppLocalizer
//

import SwiftUI

/// One coverage cell: ✓ and the count when filled, an outlined "Missing",
/// red when over the limit or an invalid URL, purple "MT", blue "Edited"
/// with the unsaved dot, or the assistant's monogram. VoiceOver reads
/// "German, Subtitle: over the limit".
struct CoverageCellButton: View {
    let cell: ListingCoverageCell
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
                .font(.callout)
                .monospacedDigit()
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 22)
                .background(background, in: RoundedRectangle(cornerRadius: Radius.badge, style: .continuous))
                .overlay {
                    if case .missing = cell.state {
                        RoundedRectangle(cornerRadius: Radius.badge, style: .continuous)
                            .strokeBorder(Palette.separator2, lineWidth: 1)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(cell.accessibilityLabel))
        .accessibilityHint(Text("Opens the editor"))
        .accessibilityIdentifier("storePage.cell.\(cell.key.locale.code).\(cell.key.field.rawValue)")
    }

    @ViewBuilder
    private var label: some View {
        switch cell.state {
        case .filled:
            HStack(spacing: 3) {
                Image(systemName: "checkmark")
                    .imageScale(.small)
                if !cell.text.isEmpty { Text(cell.text) }
            }
            .foregroundStyle(Palette.label2)
        case .missing:
            Text(cell.text)
                .foregroundStyle(Palette.label3)
        case .overLimit, .invalidURL:
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.triangle")
                    .imageScale(.small)
                Text(cell.text)
            }
            .fontWeight(.semibold)
            .foregroundStyle(Palette.danger)
        case .machineTranslated:
            Label(cell.text, systemImage: "sparkle")
                .labelStyle(.titleAndIcon)
                .fontWeight(.medium)
                .foregroundStyle(Palette.machineTranslated)
        case .edited:
            HStack(spacing: Spacing.xxSmall) {
                UnsavedDot(size: 6)
                Text(cell.text)
            }
            .foregroundStyle(Palette.accentText)
        case let .proposed(client):
            HStack(spacing: Spacing.xxSmall) {
                MonogramTag(client: client)
                Text(cell.text)
            }
            .foregroundStyle(Palette.label)
        case .notApplicable:
            Text(cell.text)
                .foregroundStyle(Palette.label3)
        }
    }

    private var background: Color {
        switch cell.state {
        case .overLimit, .invalidURL: Palette.dangerTint
        case .machineTranslated: Palette.machineTranslatedTint
        case .edited: Palette.accentTint
        case .filled, .missing, .proposed, .notApplicable: .clear
        }
    }
}
