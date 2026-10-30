//
//  AssistantConnectedCard.swift
//  AppLocalizer
//

import SwiftUI

/// The overview's line once an assistant has called AppLocalizer (which
/// one, its project, what it may do and when it last called) or an API key
/// is ready (its model and what it reads), with Ask for Suggestions… or
/// Generate Suggestions…, and Details (the Assistant button's popover).
struct AssistantConnectedCard: View {
    let status: AssistantStatus
    /// "Claude Code is connected", "Anthropic API is ready".
    let title: String
    let detail: String
    let onAsk: () -> Void
    let onDetails: () -> Void

    init(client: MCPPairedClient, editsDrafts: Bool, onAsk: @escaping () -> Void, onDetails: @escaping () -> Void) {
        status = .connected(client: client.name)
        title = String(localized: "\(client.name) is connected")
        detail = Self.detail(client: client, editsDrafts: editsDrafts)
        self.onAsk = onAsk
        self.onDetails = onDetails
    }

    init(keyClient: String, summary: String, onAsk: @escaping () -> Void, onDetails: @escaping () -> Void) {
        status = .ready(client: keyClient)
        title = String(localized: "\(keyClient) is ready")
        detail = summary
        self.onAsk = onAsk
        self.onDetails = onDetails
    }

    var body: some View {
        Card(padding: Spacing.medium + 2) {
            HStack(spacing: Spacing.medium) {
                AssistantStatusDot(status: status)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(title), \(detail)"))
                .accessibilityIdentifier("overview.assistantConnected.summary")
                Button(status.isReady ? String(localized: "Generate Suggestions…") : String(localized: "Ask for Suggestions…"), action: onAsk)
                    .accessibilityIdentifier("overview.assistantConnected.ask")
                Button("Details", action: onDetails)
                    .accessibilityIdentifier("overview.assistantConnected.details")
            }
            .controlSize(.small)
        }
        .accessibilityIdentifier("overview.assistantConnected")
    }

    /// "Project ~/Developer/Lumen · suggests only · last call 2 min ago".
    private static func detail(client: MCPPairedClient, editsDrafts: Bool) -> String {
        var parts: [String] = []
        if let directory = client.workingDirectory { parts.append(String(localized: "Project \(directory)")) }
        parts.append(editsDrafts ? String(localized: "suggests and edits drafts") : String(localized: "suggests only"))
        if let seen = client.lastSeenAt {
            parts.append(String(localized: "last call \(seen.formatted(.relative(presentation: .named)))"))
        }
        return parts.joined(separator: " · ")
    }
}
