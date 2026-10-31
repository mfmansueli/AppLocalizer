//
//  AssistantConnectedCard.swift
//  AppLocalizer
//

import SwiftUI

/// The overview's line once an assistant has called AppLocalizer (which
/// one, its project, what it may do and when it last called) or an API key
/// is ready (its model and what it reads), with Suggest Everything… (its
/// waiting popover hangs from it) or, with a key, Generate Store Page
/// Suggestions…, and Details (the Assistant button's popover). With a key,
/// a line under the card says what needs an assistant that reads the code.
struct AssistantConnectedCard<Popover: View>: View {
    let status: AssistantStatus
    /// "Claude Code is connected", "Anthropic API is ready".
    let title: String
    let detail: String
    @Binding var isPopoverPresented: Bool
    let onPrimary: () -> Void
    let onDetails: () -> Void
    var onAddAssistant: () -> Void = {}
    @ViewBuilder let popover: () -> Popover

    init(
        client: MCPPairedClient,
        editsDrafts: Bool,
        isPopoverPresented: Binding<Bool>,
        onSuggestEverything: @escaping () -> Void,
        onDetails: @escaping () -> Void,
        @ViewBuilder popover: @escaping () -> Popover
    ) {
        status = .connected(client: client.name)
        title = String(localized: "\(client.name) is connected")
        detail = Self.detail(client: client, editsDrafts: editsDrafts)
        _isPopoverPresented = isPopoverPresented
        onPrimary = onSuggestEverything
        self.onDetails = onDetails
        self.popover = popover
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
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
                    Button(status.isReady ? String(localized: "Generate Store Page Suggestions…") : String(localized: "Suggest Everything…"), action: onPrimary)
                        .buttonStyle(.borderedProminent)
                        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom, content: popover)
                        .accessibilityIdentifier("overview.assistantConnected.ask")
                    Button("Details", action: onDetails)
                        .accessibilityIdentifier("overview.assistantConnected.details")
                }
                .controlSize(.small)
            }
            .accessibilityIdentifier("overview.assistantConnected")
            if status.isReady {
                HStack(spacing: Spacing.xSmall) {
                    Text("Age Rating, Accessibility, App Review and categories need an assistant that reads the code.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                    Button("Add One…", action: onAddAssistant)
                        .buttonStyle(.link)
                        .font(.caption)
                        .accessibilityIdentifier("overview.assistantConnected.addOne")
                }
                .padding(.horizontal, Spacing.medium)
                .accessibilityElement(children: .contain)
            }
        }
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

extension AssistantConnectedCard where Popover == EmptyView {
    /// With an API key: Generate Store Page Suggestions…, which opens on the
    /// Store Page.
    init(
        keyClient: String,
        summary: String,
        onGenerate: @escaping () -> Void,
        onDetails: @escaping () -> Void,
        onAddAssistant: @escaping () -> Void
    ) {
        status = .ready(client: keyClient)
        title = String(localized: "\(keyClient) is ready")
        detail = summary
        _isPopoverPresented = .constant(false)
        onPrimary = onGenerate
        self.onDetails = onDetails
        self.onAddAssistant = onAddAssistant
        popover = { EmptyView() }
    }
}
