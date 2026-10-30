//
//  SuggestionStreamingBanner.swift
//  AppLocalizer
//

import SwiftUI

/// While an assistant sends suggestions: "CC Claude Code · Sending
/// suggestions · 2 of 4", with a bar when it said how many. Each one shows
/// under its field as it arrives.
struct SuggestionStreamingBanner: View {
    let request: AssistantSuggestionRequest

    var body: some View {
        HStack(spacing: Spacing.small) {
            AssistantChip(name: request.client)
            ProgressView()
                .controlSize(.small)
            Text(request.progressText)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let fraction = request.fraction {
                ProgressView(value: fraction)
                    .frame(width: 140)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityIdentifier("suggestions.streaming")
    }
}

#Preview {
    SuggestionStreamingBanner(
        request: AssistantSuggestionRequest(
            appID: "1", area: .storePage, client: "Claude Code", prompt: "", startedAt: .now, received: 2, total: 4
        )
    )
    .padding()
    .frame(width: 700)
}
