//
//  AssistantIntroCard.swift
//  AppLocalizer
//

import SwiftUI

/// The overview's card about using your own AI assistant or an API key,
/// until one is set up or the card is hidden: what each can do, the three
/// steps (the first two ticked once the server waits for a first call),
/// Set Up Assistant… or Finish Setup…, and What Can It Do?.
struct AssistantIntroCard: View {
    let appName: String
    let status: AssistantStatus
    let onSetUp: () -> Void
    let onWhatItDoes: () -> Void
    let onHide: () -> Void

    var body: some View {
        Card(padding: Spacing.large + 2) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                Image(systemName: "terminal")
                    .font(.title2)
                    .foregroundStyle(Palette.accentText)
                    .frame(width: 36, height: 36)
                    .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    HStack(spacing: Spacing.small) {
                        Text("Use your own AI assistant or API key with AppLocalizer")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        Pill(text: statusText, style: status.isWaiting ? .warning : .outline)
                            .accessibilityIdentifier("overview.assistantIntro.status")
                    }
                    Text("""
                    Connect Claude Code, Claude Desktop, Cursor, Codex or any other MCP client and your assistant reads \
                    \(appName)’s code to suggest store text, App Review notes, age rating and accessibility answers, privacy \
                    answers and screenshot captions. Or paste an API key from Anthropic, OpenAI or Google Gemini and get text \
                    suggestions in one click, without the code. Every suggestion waits here for you to accept it. Nothing goes \
                    to App Store Connect until you push.
                    """)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onHide) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .help(String(localized: "Hide this card"))
                .accessibilityLabel(Text("Hide this card"))
                .accessibilityIdentifier("overview.assistantIntro.hide")
            }
            steps
                .padding(.vertical, Spacing.xxSmall)
            HStack(spacing: Spacing.small) {
                Button(status.setupTitle, action: onSetUp)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("overview.assistantIntro.setUp")
                Button("What Can It Do?", action: onWhatItDoes)
                    .accessibilityIdentifier("overview.assistantIntro.whatItDoes")
                Text("Without an assistant, built-in suggestions still work.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .controlSize(.small)
        }
        .accessibilityIdentifier("overview.assistantIntro")
    }

    /// "Not set up", or "Waiting for Claude Code".
    private var statusText: String {
        guard status.isWaiting, let client = status.clientName else { return status.title }
        return String(localized: "Waiting for \(client)")
    }

    private var steps: some View {
        HStack(alignment: .top, spacing: Spacing.large) {
            ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                let isDone = status.isWaiting && index < 2
                HStack(alignment: .top, spacing: Spacing.small) {
                    Group {
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                        } else {
                            Text(index + 1, format: .number)
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .frame(width: 20, height: 20)
                    .foregroundStyle(isDone ? Color.white : Palette.label)
                    .background(isDone ? Palette.accent : Palette.fill3, in: Circle())
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(step.title)
                            .font(.callout.weight(.semibold))
                        Text(step.detail)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(isDone ? String(localized: "Done: \(step.title)") : String(localized: "Step \(index + 1): \(step.title)")))
            }
        }
    }

    private static let steps: [(title: String, detail: String)] = [
        (String(localized: "Choose how"), String(localized: "Your assistant through MCP, or an API key from Anthropic, OpenAI or Google Gemini.")),
        (String(localized: "Connect it"), String(localized: "Paste one command into your assistant, or paste the key here.")),
        (String(localized: "Ask for suggestions"), String(localized: "From the Assistant button or any suggestion bar.")),
    ]
}

#Preview {
    VStack {
        AssistantIntroCard(appName: "Lumen Journal", status: .notSetUp, onSetUp: {}, onWhatItDoes: {}, onHide: {})
        AssistantIntroCard(appName: "Lumen Journal", status: .waiting(client: "Claude Code"), onSetUp: {}, onWhatItDoes: {}, onHide: {})
    }
    .padding()
    .frame(width: 900)
}
