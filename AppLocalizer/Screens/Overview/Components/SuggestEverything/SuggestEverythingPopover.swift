//
//  SuggestEverythingPopover.swift
//  AppLocalizer
//

import SwiftUI

/// After Suggest Everything…: the prompt is on the clipboard to paste into
/// the assistant (or its MCP shortcut), what it covers page by page, and
/// "Waiting for Claude Code to start…" with Cancel. Says so when a
/// per-page Ask is still sending, since the run skips what that covers. It
/// closes on its own when the assistant announces its plan.
struct SuggestEverythingPopover: View {
    let run: SuggestionRun
    let scope: SuggestEverythingScope
    /// A per-page Ask for the same app that's still sending.
    var busyRequest: AssistantSuggestionRequest?
    let onCopyAgain: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggest Everything with \(run.client)")
                .font(.headline)
            if let busyRequest {
                Text(Self.busyText(busyRequest))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, Spacing.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.warningTint, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                    .accessibilityIdentifier("everything.busy")
            }
            Text("\(run.client) reads the project and suggests the fields below. Paste this prompt into it; suggestions show up here as they arrive, and nothing changes until you accept them.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            Text(run.prompt)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .accessibilityIdentifier("everything.prompt")
            HStack(alignment: .top, spacing: Spacing.small) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Copied to the clipboard. Shortcut in \(run.client):")
                        .font(.caption)
                    Text(MCPPrompt.suggestAll.slashCommand)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button("Copy Again", action: onCopyAgain)
                    .controlSize(.small)
                    .accessibilityIdentifier("everything.copyAgain")
            }
            if !scope.rows.isEmpty {
                coverage
            }
            Text("""
            Fields you’ve changed are left alone, and suggestions you haven’t reviewed stay. Built-in suggestions don’t \
            need the assistant and are already here.
            """)
            .font(.caption2)
            .foregroundStyle(Palette.label2)
            .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Spacing.small) {
                ProgressView()
                    .controlSize(.small)
                Text("Waiting for \(run.client) to start…")
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Cancel", action: onCancel)
                    .controlSize(.small)
                    .accessibilityIdentifier("everything.cancel")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, Spacing.small)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .accessibilityElement(children: .contain)
        }
        .padding(Spacing.large)
        .frame(width: 480)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("everything.popover")
    }

    private var coverage: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("WHAT IT COVERS")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Palette.label2)
            VStack(spacing: 0) {
                ForEach(Array(scope.rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { Divider() }
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                        Text(row.page.title)
                            .font(.callout.weight(.semibold))
                            .frame(width: 110, alignment: .leading)
                        Text(row.detail)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if row.isLocked {
                            Image(systemName: "lock")
                                .font(.caption)
                                .accessibilityHidden(true)
                        }
                    }
                    .foregroundStyle(row.isLocked ? Palette.label3 : Palette.label)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("everything.covers.\(row.page.rawValue)")
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                    .strokeBorder(Palette.separator2, lineWidth: 0.5)
            }
        }
    }

    /// "Claude Code is still sending Store Page suggestions (2 of 4). Those
    /// keep coming; this run skips the fields they cover."
    static func busyText(_ request: AssistantSuggestionRequest) -> String {
        let area = request.area.title
        guard let total = request.total else {
            return String(localized: "\(request.client) is still sending \(area) suggestions. Those keep coming; this run skips the fields they cover.")
        }
        return String(localized: "\(request.client) is still sending \(area) suggestions (\(request.received) of \(total)). Those keep coming; this run skips the fields they cover.")
    }
}

#Preview {
    SuggestEverythingPopover(
        run: SuggestionRun(
            id: "run_1",
            appID: "1",
            client: "Claude Code",
            prompt: SuggestEverythingScope(appName: "Lumen Journal", versionString: "1.4").prompt,
            phase: .waiting,
            startedAt: .now,
            lastActivityAt: .now
        ),
        scope: SuggestEverythingScope(appName: "Lumen Journal", versionString: "1.4"),
        onCopyAgain: {},
        onCancel: {}
    )
}
