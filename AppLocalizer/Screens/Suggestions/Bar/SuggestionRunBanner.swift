//
//  SuggestionRunBanner.swift
//  AppLocalizer
//

import SwiftUI

/// On a Store Page language or App Information page while Suggest
/// Everything receives: "CC Claude Code · Suggesting everything · 6 of 18.
/// Here: 2 of 3 arrived.", the run's bar and Overview, where its progress
/// card is.
struct SuggestionRunBanner: View {
    let run: SuggestionRun
    /// "Here: 2 of 3 arrived."; nil when the run covers nothing here.
    var hereText: String?
    let onOverview: () -> Void

    var body: some View {
        HStack(spacing: Spacing.small) {
            AssistantChip(name: run.client)
            ProgressView()
                .controlSize(.small)
            Group {
                if let hereText {
                    Text("\(run.progressText). \(Text(hereText).foregroundStyle(Palette.label2))")
                } else {
                    Text("\(run.progressText).")
                }
            }
            .font(.callout)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("suggestions.run.text")
            MeterBar(fraction: run.fraction, tint: Palette.accent)
                .frame(width: 100)
                .accessibilityHidden(true)
            Button("Overview", action: onOverview)
                .controlSize(.small)
                .accessibilityIdentifier("suggestions.run.overview")
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityIdentifier("suggestions.run")
    }
}
