//
//  AssistantPopoverContent.swift
//  AppLocalizer
//

import SwiftUI

/// The Assistant button's popover: "AI Assistant" and its status; once
/// connected, which client, its project and its latest calls (with an API
/// key, the key's API and model and its latest requests), else what an
/// assistant could do; the proposals waiting for review; what it can
/// suggest here; and Settings…, Suggest Everything… (Show Progress while it
/// runs) with Ask About This Page… on the Store Page and App Information,
/// Generate Suggestions… with a key, or Set Up Assistant….
struct AssistantPopoverContent: View {
    let status: AssistantStatus
    let activity: AssistantActivity
    /// The client the button names, once paired.
    let client: MCPPairedClient?
    let editsDrafts: Bool
    let recentCalls: [MCPLogEntry]
    /// The API key, when it's what suggests.
    var key: KeyAssistantConfiguration?
    var recentRequests: [KeyAssistantRequestLog] = []
    /// The name of an app in the library, by Apple ID.
    let appName: (StoreApp.ID) -> String
    var canOpenScreenshotProposals = false
    /// Suggest Everything is receiving: Show Progress.
    var isSuggestingEverything = false
    /// On the Store Page or App Information: Ask About This Page….
    var canAskAboutPage = false
    var onReviewProposals: () -> Void = {}
    var onScreenshotProposals: () -> Void = {}
    var onAsk: () -> Void = {}
    var onSuggestEverything: () -> Void = {}
    var onSetUp: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            header
            if status.isConnected {
                clientBox
            } else if status.isReady, let key {
                keyBox(key)
            } else {
                Text(introText)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if activity.isWorking || activity.proposalCount > 0 {
                proposals
            }
            capabilities
            Text("Runs only on this Mac (127.0.0.1). Your App Store Connect key stays in the Keychain; assistants never see it, and they can’t push.")
                .font(.caption2)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            buttons
        }
        .padding(Spacing.large)
        .frame(width: 380, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspace.assistantPopover")
    }

    private var header: some View {
        HStack(spacing: Spacing.small) {
            Text("AI Assistant")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: Spacing.xxSmall) {
                AssistantStatusDot(status: status)
                Text(status.title)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("assistant.status")
        }
    }

    private var introText: String {
        status.isWaiting
            ? String(localized: "The local server is on, but no assistant has called it yet. Finish setup to see the command again and test it.")
            : String(localized: """
            Connect your own assistant (Claude Code, Claude Desktop, Cursor, Codex or any MCP client), or add an API key \
            from Anthropic, OpenAI or Google Gemini. AppLocalizer then suggests what to put in its fields, and you accept \
            or dismiss every suggestion.
            """)
    }

    @ViewBuilder
    private var clientBox: some View {
        if let client {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(spacing: Spacing.xSmall) {
                    AssistantChip(name: client.name, monogram: client.monogram)
                    Text(editsDrafts ? String(localized: "suggests and edits drafts") : String(localized: "suggests only"))
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                if let directory = client.workingDirectory {
                    Text("Project \(directory)")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if !recentCalls.isEmpty {
                    Text("RECENT CALLS")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.label2)
                    ForEach(recentCalls) { call in
                        HStack(spacing: Spacing.small) {
                            Text([call.tool, call.target].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.caption.monospaced())
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(call.date, format: .relative(presentation: .named))
                                .font(.caption2)
                                .foregroundStyle(Palette.label2)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("assistant.client")
        }
    }

    /// "Anthropic API · Claude Sonnet 5.5", where the key is and what it
    /// reads, then Recent Requests.
    private func keyBox(_ key: KeyAssistantConfiguration) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(key.vendor.apiName) · \(key.model.name)")
                    .font(.callout.weight(.semibold))
                Text(Self.keyPlace(key))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
            if !recentRequests.isEmpty {
                Text("RECENT REQUESTS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                ForEach(recentRequests) { request in
                    HStack(spacing: Spacing.small) {
                        Text(request.title)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(Self.requestDetail(request))
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(Palette.label2)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assistant.key")
    }

    /// "Key sk-ant-…x7Qa in the Keychain · reads ~/Developer/Lumen’s
    /// commits".
    static func keyPlace(_ key: KeyAssistantConfiguration) -> String {
        let place = String(localized: "Key \(key.maskedKey) in the Keychain")
        guard key.readsProjectFolder, let path = key.projectFolderPath else { return place }
        return String(localized: "\(place) · reads \(path)’s commits")
    }

    /// "9.4k tokens · 2 min ago".
    static func requestDetail(_ request: KeyAssistantRequestLog, now: Date = .now) -> String {
        let ago = request.date.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
        let tokens = KeyAssistantTokens.formatted(request.tokens)
        return String(localized: "\(tokens) tokens · \(now.timeIntervalSince(request.date) < 60 ? String(localized: "just now") : ago)")
    }

    private var proposals: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Waiting for you")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Palette.label2)
            if activity.rows.isEmpty {
                Text("Nothing yet. Proposals show here as \(activity.client ?? String(localized: "the assistant")) sends them.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(activity.rows) { entry in
                HStack {
                    Text(appName(entry.appID))
                        .lineLimit(1)
                    Spacer(minLength: Spacing.large)
                    Text(AssistantActivity.proposalsText(entry.count))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(entry.count == 0 ? Palette.label3 : Palette.label2)
                }
                .accessibilityElement(children: .combine)
            }
            HStack(spacing: Spacing.xSmall) {
                Button("Review Proposals…", action: onReviewProposals)
                    .disabled(activity.apps.isEmpty || (activity.reviewCount == 0 && !canOpenScreenshotProposals))
                    .accessibilityIdentifier("workspace.reviewProposals")
                if activity.reviewCount > 0, canOpenScreenshotProposals {
                    Button("Screenshot Proposals…", action: onScreenshotProposals)
                        .accessibilityIdentifier("workspace.screenshotProposals")
                }
            }
            .controlSize(.small)
        }
    }

    private var capabilities: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("WHAT IT CAN SUGGEST HERE")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Palette.label2)
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: Spacing.small, verticalSpacing: Spacing.xxSmall) {
                ForEach(Self.capabilities(withKey: status.isReady), id: \.title) { item in
                    GridRow {
                        Text(item.title)
                            .font(.caption.weight(.semibold))
                            .frame(width: 110, alignment: .leading)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: Spacing.xSmall) {
            Spacer()
            SettingsLink {
                Text("Settings…")
            }
            .accessibilityIdentifier("assistant.settings")
            if status.isConnected {
                if canAskAboutPage, !isSuggestingEverything {
                    Button("Ask About This Page…", action: onAsk)
                        .accessibilityIdentifier("assistant.ask")
                }
                Button(isSuggestingEverything ? String(localized: "Show Progress") : String(localized: "Suggest Everything…"), action: onSuggestEverything)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("assistant.suggestEverything")
            } else if status.isReady {
                Button("Generate Suggestions…", action: onAsk)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("assistant.ask")
            } else {
                Button(status.setupTitle, action: onSetUp)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("assistant.setUp")
            }
        }
        .controlSize(.small)
    }

    /// With an API key, what needs the code says it needs an MCP
    /// assistant.
    static func capabilities(withKey: Bool) -> [(title: String, detail: String)] {
        func fromCode(_ detail: String) -> String {
            withKey ? String(localized: "Needs an MCP assistant: \(detail)") : detail.prefix(1).uppercased() + detail.dropFirst()
        }
        return [
            (String(localized: "Store Page"), String(localized: "What’s New, promotional text, subtitle, keywords")),
            (
                String(localized: "App Information"),
                withKey ? String(localized: "Copyright and release; categories need an MCP assistant") : String(localized: "Categories, copyright, release")
            ),
            (String(localized: "Age Rating"), fromCode(String(localized: "answers from what the app actually does"))),
            (String(localized: "Accessibility"), fromCode(String(localized: "which features the code supports, per device"))),
            (String(localized: "App Review"), fromCode(String(localized: "notes and demo steps, from your code"))),
            (String(localized: "App Privacy"), fromCode(String(localized: "answers from SDKs and privacy manifests"))),
            (String(localized: "Screenshots"), String(localized: "Captions in every language")),
        ]
    }
}
