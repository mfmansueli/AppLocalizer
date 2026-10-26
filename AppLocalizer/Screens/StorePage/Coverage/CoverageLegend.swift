//
//  CoverageLegend.swift
//  AppLocalizer
//

import SwiftUI

/// What the coverage cells mean, under the grid. Hidden from VoiceOver,
/// since every cell says its state.
struct CoverageLegend: View {
    /// The design's example monogram, "CC".
    private static let exampleClient = "Claude Code"

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Label("Filled", systemImage: "checkmark")
                .foregroundStyle(Palette.label2)
            swatch(Text("Missing"), foreground: Palette.label3, background: .clear, outlined: true)
            swatch(Text("Over the limit"), foreground: Palette.danger, background: Palette.dangerTint)
            swatch(Text("Machine-translated"), foreground: Palette.machineTranslated, background: Palette.machineTranslatedTint)
            swatch(
                HStack(spacing: Spacing.xxSmall) {
                    UnsavedDot(size: 6)
                    Text("Edited, not pushed")
                },
                foreground: Palette.accentText,
                background: Palette.accentTint
            )
            swatch(
                HStack(spacing: Spacing.xxSmall) {
                    MonogramTag(client: Self.exampleClient)
                    Text("Proposed by an assistant")
                },
                foreground: Palette.label,
                background: .clear,
                outlined: true
            )
            Spacer(minLength: 0)
        }
        .font(.caption)
        .lineLimit(1)
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .accessibilityHidden(true)
    }

    private func swatch(_ content: some View, foreground: Color, background: Color, outlined: Bool = false) -> some View {
        content
            .fontWeight(.medium)
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.xSmall)
            .frame(height: 18)
            .background(background, in: RoundedRectangle(cornerRadius: Radius.badge, style: .continuous))
            .overlay {
                if outlined {
                    RoundedRectangle(cornerRadius: Radius.badge, style: .continuous)
                        .strokeBorder(Palette.separator2, lineWidth: 1)
                }
            }
    }
}
