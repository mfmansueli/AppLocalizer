//
//  ClaudeCodeRunOutputSheet.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// Show Output: every step of a run AppLocalizer started, live while it
/// works, with the prompt and how to continue it in Terminal.
struct ClaudeCodeRunOutputSheet: View {
    let runID: ClaudeCodeRun.ID

    @Environment(ClaudeCodeLauncher.self) private var launcher
    @Environment(\.dismiss) private var dismiss
    @State private var showsPrompt = false
    @State private var copiedResume = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let run = launcher.run(runID) {
                header(run)
                    .padding(.horizontal, 22)
                    .padding(.top, Spacing.xLarge)
                    .padding(.bottom, Spacing.medium)
                Divider()
                timeline(run)
                Divider()
                footer(run)
                    .padding(.horizontal, 22)
                    .padding(.vertical, Spacing.medium)
            } else {
                ContentUnavailableView("This run is gone", systemImage: "terminal")
                    .frame(maxWidth: .infinity, minHeight: 240)
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
                .padding(Spacing.medium)
            }
        }
        .frame(width: 640)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("claudeCode.output")
    }

    // MARK: - Header

    private func header(_ run: ClaudeCodeRun) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Text("\(run.purpose.title) · \(run.appName)")
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                phasePill(run)
                Spacer(minLength: 0)
            }
            Text(summary(run))
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .truncationMode(.middle)
                .accessibilityIdentifier("claudeCode.output.summary")
        }
    }

    private func phasePill(_ run: ClaudeCodeRun) -> some View {
        let (title, tint): (String, Color) = switch run.phase {
        case .starting, .working: (String(localized: "Working"), Palette.accent)
        case .finished: (String(localized: "Finished"), Palette.positive)
        case .stopped: (String(localized: "Stopped"), Palette.label2)
        case .failed: (String(localized: "Failed"), Palette.danger)
        }
        return Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.12), in: Capsule())
            .accessibilityIdentifier("claudeCode.output.phase")
    }

    /// "Claude Code 2.1.316 · ~/Developer/Lumen · 4 min · 9 calls to
    /// AppLocalizer".
    private func summary(_ run: ClaudeCodeRun) -> String {
        var parts = [run.claudeVersion.map { "Claude Code \($0)" } ?? "Claude Code", run.displayDirectory]
        let minutes = Int(run.elapsed(at: .now) / 60)
        parts.append(minutes < 1 ? String(localized: "under a minute") : String(localized: "\(minutes) min"))
        switch run.appLocalizerCalls {
        case 0: break
        case 1: parts.append(String(localized: "1 call to AppLocalizer"))
        case let calls: parts.append(String(localized: "\(calls) calls to AppLocalizer"))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Timeline

    private func timeline(_ run: ClaudeCodeRun) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(run.timeline) { item in
                        row(item)
                            .id(item.id)
                    }
                    if run.isActive {
                        HStack(spacing: Spacing.small) {
                            ProgressView()
                                .controlSize(.small)
                            Text(run.statusTitle)
                                .font(.caption)
                                .foregroundStyle(Palette.label2)
                        }
                        .padding(.vertical, Spacing.small)
                        .id(Self.bottomID)
                    }
                    if let result = run.result, !result.text.isEmpty {
                        Text(result.text)
                            .font(.callout)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(Spacing.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                            .padding(.top, Spacing.small)
                            .accessibilityIdentifier("claudeCode.output.result")
                    }
                    if !run.isActive, run.phase != .finished || !run.denials.isEmpty {
                        ClaudeCodeRunStatusView(run: run, showsOutputButton: false)
                            .padding(.top, Spacing.small)
                    }
                    prompt(run)
                        .padding(.top, Spacing.medium)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, Spacing.medium)
            }
            .frame(minHeight: 260, maxHeight: 440)
            .onChange(of: run.activity.last?.id) {
                guard run.isActive else { return }
                withAnimation { proxy.scrollTo(Self.bottomID, anchor: .bottom) }
            }
        }
    }

    private static let bottomID = -1

    private func row(_ item: ClaudeCodeActivity) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: item.systemImage)
                .font(.caption)
                .foregroundStyle(item.kind == .problem ? Palette.warning : item.kind == .appLocalizer ? Palette.accent : Palette.label2)
                .frame(width: 16)
                .accessibilityHidden(true)
            Text(item.text)
                .font(item.kind == .command ? .caption.monospaced() : .caption)
                .foregroundStyle(item.kind == .said ? Palette.label2 : Palette.label)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.date, format: .dateTime.hour().minute())
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Palette.label3)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }

    private func prompt(_ run: ClaudeCodeRun) -> some View {
        DisclosureGroup(isExpanded: $showsPrompt) {
            Text(run.prompt)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .padding(.top, Spacing.xSmall)
        } label: {
            Text("Prompt")
                .font(.callout.weight(.medium))
        }
        .accessibilityIdentifier("claudeCode.output.prompt")
    }

    // MARK: - Footer

    private func footer(_ run: ClaudeCodeRun) -> some View {
        HStack(spacing: Spacing.small) {
            if let command = run.resumeCommand {
                Button(copiedResume ? String(localized: "Copied") : String(localized: "Copy Resume Command")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                    copiedResume = true
                }
                .help(command)
                .accessibilityIdentifier("claudeCode.output.resume")
                Text("claude --resume in \(run.displayDirectory)")
                    .font(.caption.monospaced())
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: Spacing.small)
            if run.isActive {
                Button("Stop") { launcher.stop(run.id) }
                    .accessibilityIdentifier("claudeCode.output.stop")
            }
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("claudeCode.output.done")
        }
    }
}
