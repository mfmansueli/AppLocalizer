//
//  AIProviderKeyStatusLine.swift
//  AppLocalizer
//

import SwiftUI

/// The line under Settings → Translation's API key field: "Saved ·
/// connected to Anthropic · 182 ms" with a green check, a spinner while the
/// check runs, or why the key isn't working, with Check Again. Nothing with
/// no key saved. The icon isn't the only cue: the text says it too.
struct AIProviderKeyStatusLine: View {
    let status: AIProviderKeyStatus
    let onCheckAgain: () -> Void

    var body: some View {
        if let text = status.text {
            HStack(spacing: Spacing.xSmall) {
                icon
                    .accessibilityHidden(true)
                Text(text)
                    .foregroundStyle(textColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHint(Text(status.detail ?? ""))
                    .accessibilityIdentifier("settings.apiKeyStatus")
                if status.canCheckAgain {
                    Button("Check Again", action: onCheckAgain)
                        .buttonStyle(.link)
                        .accessibilityIdentifier("settings.apiKeyCheckAgain")
                }
            }
            .font(.caption)
            .help(Text(status.detail ?? ""))
            .accessibilityElement(children: .contain)
            .task(id: status) {
                // The check finishes while focus is elsewhere; say how it went.
                if case .checking = status { return }
                AccessibilityNotification.Announcement(text).post()
            }
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch status {
        case .notSaved:
            EmptyView()
        case .checking:
            ProgressView()
                .controlSize(.mini)
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Palette.positive)
        case .rejected:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(Palette.danger)
        case .unchecked:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.warningMark)
        }
    }

    private var textColor: Color {
        switch status {
        case .notSaved, .checking: Palette.label2
        case .connected: Palette.label
        case .rejected: Palette.danger
        case .unchecked: Palette.warning
        }
    }
}

#Preview {
    VStack(alignment: .trailing, spacing: Spacing.medium) {
        AIProviderKeyStatusLine(status: .checking(.anthropic)) {}
        AIProviderKeyStatusLine(status: .connected(AIProviderKeyCheck(vendor: .anthropic, milliseconds: 182, date: .now))) {}
        AIProviderKeyStatusLine(status: .rejected(.openAI)) {}
        AIProviderKeyStatusLine(status: .unchecked(.anthropic, reason: "You’re offline.")) {}
    }
    .padding()
}
