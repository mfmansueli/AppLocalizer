//
//  AssistantLaunchedRunsList.swift
//  AppLocalizer
//

import SwiftUI

/// In the Assistant button's popover: the Claude Code runs AppLocalizer
/// started that are still going or failed, since they keep going with
/// every popover closed, with Show (the run's output) and Stop.
struct AssistantLaunchedRunsList: View {
    @Environment(ClaudeCodeLauncher.self) private var launcher
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if !runs.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("STARTED FROM APPLOCALIZER")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                VStack(spacing: 0) {
                    ForEach(Array(runs.enumerated()), id: \.element.id) { index, run in
                        if index > 0 { Divider() }
                        row(run)
                    }
                }
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("assistant.runs")
        }
    }

    /// Going, or failed and not dismissed, newest first.
    private var runs: [ClaudeCodeRun] {
        Array(launcher.runs.filter { $0.isActive || $0.failure != nil }.reversed().prefix(4))
    }

    private func row(_ run: ClaudeCodeRun) -> some View {
        HStack(spacing: Spacing.small) {
            if run.isActive {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Palette.warning)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("\(run.purpose.title) · \(run.appName)")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                TimelineView(.periodic(from: run.startedAt, by: 1)) { context in
                    Text(detail(run, at: context.date))
                        .font(.caption2.monospaced())
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Show") {
                dismiss()
                launcher.shownRunID = run.id
            }
            .accessibilityIdentifier("assistant.runs.show")
            if run.isActive {
                Button("Stop") { launcher.stop(run.id) }
                    .accessibilityIdentifier("assistant.runs.stop")
            }
        }
        .controlSize(.small)
        .padding(.horizontal, 10)
        .padding(.vertical, Spacing.xSmall)
        .accessibilityElement(children: .contain)
    }

    /// "xcrun simctl io booted screenshot · 2:05", or why it failed.
    private func detail(_ run: ClaudeCodeRun, at date: Date) -> String {
        if let failure = run.failure { return failure.title }
        let elapsed = ClaudeCodeRunStatusView.duration(run.elapsed(at: date))
        guard let step = run.latestStep else { return "\(run.statusTitle) · \(elapsed)" }
        return "\(step) · \(elapsed)"
    }
}
