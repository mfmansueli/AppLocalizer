//
//  ClaudeCodeRunStatusView.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// A run AppLocalizer started, wherever it was started from: while it
/// works, a strip with where, how long, its latest step, Show Output and
/// Stop; when it ends, how it went. A failure says why in words with the
/// way through (Open in Terminal, Try Again, Copy Prompt), and a run that
/// finished with refused steps lists them with the resume command.
struct ClaudeCodeRunStatusView: View {
    let run: ClaudeCodeRun
    /// Show Output: by default the main window's sheet; popovers close
    /// first, and Settings shows its own.
    var onShowOutput: (() -> Void)?
    /// False inside Show Output itself, which has no Show Output or
    /// Dismiss (the sheet would lose its run).
    var showsOutputButton = true
    /// After Try Again started the new run.
    var onRetried: (ClaudeCodeRun.ID) -> Void = { _ in }
    /// After Dismiss forgot the run, e.g. to end the request it was for.
    var onDismiss: () -> Void = {}

    @Environment(ClaudeCodeLauncher.self) private var launcher
    @State private var terminalUnavailable = false
    @State private var copied: CopiedText?

    var body: some View {
        Group {
            switch run.phase {
            case .starting, .working: working
            case let .failed(failure): failed(failure)
            case .finished where !run.denials.isEmpty: denied
            case .finished, .stopped: ended
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("claudeCode.run")
    }

    // MARK: - Working

    private var working: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                ProgressView()
                    .controlSize(.small)
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                VStack(alignment: .leading, spacing: 2) {
                    Text(run.statusTitle)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .accessibilityIdentifier("claudeCode.run.status")
                    if let step = run.latestStep {
                        Text(step)
                            .font(.caption.monospaced())
                            .foregroundStyle(Palette.label2)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .accessibilityIdentifier("claudeCode.run.step")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                elapsed
            }
            HStack(spacing: Spacing.small) {
                showOutputButton
                Button("Stop") { launcher.stop(run.id) }
                    .accessibilityIdentifier("claudeCode.run.stop")
            }
            .controlSize(.small)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
    }

    private var elapsed: some View {
        TimelineView(.periodic(from: run.startedAt, by: 1)) { context in
            Text(Self.duration(run.elapsed(at: context.date)))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Palette.label2)
        }
        .accessibilityLabel(Text("Running"))
    }

    // MARK: - Ended

    private var ended: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Image(systemName: run.phase == .stopped ? "stop.circle" : "checkmark.circle.fill")
                    .foregroundStyle(run.phase == .stopped ? Palette.label2 : Palette.positive)
                    .accessibilityHidden(true)
                Text(run.statusTitle)
                    .font(.callout.weight(.medium))
                    .accessibilityIdentifier("claudeCode.run.status")
                Text(Self.duration(run.elapsed(at: .now)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Palette.label2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            if let text = run.result?.text, !text.isEmpty, run.phase == .finished {
                Text(text)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: Spacing.small) {
                showOutputButton
                dismissButton
            }
            .controlSize(.small)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
    }

    // MARK: - Refused steps

    private var denied: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(run.statusTitle)
                    .font(.callout.weight(.semibold))
                    .accessibilityIdentifier("claudeCode.run.status")
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Palette.warning)
            }
            VStack(spacing: 0) {
                ForEach(Array(run.denials.enumerated()), id: \.offset) { index, denial in
                    if index > 0 { Divider() }
                    HStack(spacing: Spacing.small) {
                        // "Edit Info.plist" names its tool already.
                        if !denial.summary.hasPrefix(denial.toolName) {
                            Text(denial.toolName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Palette.label2)
                        }
                        Text(denial.summary)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                }
            }
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
            .accessibilityIdentifier("claudeCode.run.denials")
            Text("Runs from AppLocalizer only read the project and use AppLocalizer’s tools. To allow more, continue the same run in Terminal.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Spacing.small) {
                showOutputButton
                resumeButton
                dismissButton
            }
            .controlSize(.small)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.warningTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
    }

    // MARK: - Failed

    private func failed(_ failure: ClaudeCodeRunFailure) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(failure.title)
                        .font(.callout.weight(.semibold))
                        .accessibilityIdentifier("claudeCode.run.status")
                    Text(failure.detail)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Palette.warning)
            }
            HStack(spacing: Spacing.small) {
                if failure.suggestsTerminal {
                    Button("Open in Terminal") { terminalUnavailable = !launcher.openInTerminal(run.id) }
                        .accessibilityIdentifier("claudeCode.run.terminal")
                }
                Button(failure.needsFolder ? String(localized: "Choose Folder…") : String(localized: "Try Again"), action: retry)
                    .accessibilityIdentifier("claudeCode.run.retry")
                Button(copied == .prompt ? String(localized: "Copied") : String(localized: "Copy Prompt")) { copy(run.prompt, as: .prompt) }
                    .accessibilityIdentifier("claudeCode.run.copyPrompt")
                Spacer(minLength: 0)
                if run.activity.count > 1 { showOutputButton }
            }
            .controlSize(.small)
            if failure.suggestsTerminal {
                Text(terminalNote(for: failure))
                    .font(.caption2)
                    .foregroundStyle(terminalUnavailable ? Palette.warning : Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.warningTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
    }

    private func terminalNote(for failure: ClaudeCodeRunFailure) -> String {
        if terminalUnavailable {
            return String(localized: "Claude Code’s link isn’t set up on this Mac yet. Copy the prompt and run claude in \(run.displayDirectory).")
        }
        if case .notLoggedIn = failure {
            return String(localized: "Open in Terminal starts Claude Code in \(run.displayDirectory) with this prompt typed in; press Return after /login.")
        }
        return String(localized: "Open in Terminal starts Claude Code in \(run.displayDirectory) with this prompt typed in, so you can watch it.")
    }

    // MARK: - Buttons

    @ViewBuilder
    private var showOutputButton: some View {
        if showsOutputButton {
            Button("Show Output") {
                if let onShowOutput { onShowOutput() } else { launcher.shownRunID = run.id }
            }
            .accessibilityIdentifier("claudeCode.run.output")
        }
    }

    @ViewBuilder
    private var resumeButton: some View {
        if let command = run.resumeCommand {
            Button(copied == .resume ? String(localized: "Copied") : String(localized: "Copy Resume Command")) { copy(command, as: .resume) }
                .help(command)
                .accessibilityIdentifier("claudeCode.run.resume")
        }
    }

    @ViewBuilder
    private var dismissButton: some View {
        if showsOutputButton {
            Button("Dismiss") {
                launcher.dismiss(run.id)
                onDismiss()
            }
            .accessibilityIdentifier("claudeCode.run.dismiss")
        }
    }

    private func retry() {
        Task {
            if let id = await launcher.retry(run.id) { onRetried(id) }
        }
    }

    private func copy(_ text: String, as kind: CopiedText) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copied = kind
    }

    private enum CopiedText {
        case prompt
        case resume
    }

    // MARK: - Text

    /// "0:42", "12:05", "1:02:10".
    static func duration(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        let (hours, minutes, rest) = (seconds / 3600, seconds / 60 % 60, seconds % 60)
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, rest) : String(format: "%d:%02d", minutes, rest)
    }
}
