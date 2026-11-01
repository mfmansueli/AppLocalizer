//
//  AssistantSetupTestStep.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// Step 4, "Test": ask the assistant something that uses AppLocalizer and
/// wait for its first call, then what to ask next. When AppLocalizer
/// starts Claude Code, it sends the test prompt itself and shows the run
/// until it connects.
struct AssistantSetupTestStep: View {
    let viewModel: AssistantSetupViewModel

    @State private var outputRunID: ClaudeCodeRun.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.launches {
                launched
            } else {
                pasted
            }
        }
        .sheet(item: Binding(get: { outputRunID.map(OutputRun.init) }, set: { outputRunID = $0?.id })) { run in
            ClaudeCodeRunOutputSheet(runID: run.id)
        }
    }

    // MARK: - Pasted

    private var pasted: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Now ask \(viewModel.clientName) something that uses AppLocalizer:")
                .font(.callout)
            HStack(spacing: Spacing.small) {
                promptText
                Button("Copy") { Self.copy(AssistantSetupViewModel.testPrompt) }
                    .controlSize(.small)
            }
            if viewModel.isConnected {
                connectedBox
                Text("Things to ask next")
                    .font(.headline)
                    .padding(.top, Spacing.xxSmall)
                thingsToAskList
            } else {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Waiting for \(viewModel.clientName)’s first call…")
                            .font(.callout)
                        Text("If \(viewModel.clientName) was already open, restart it so it loads the new server.")
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(Box())
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("assistantSetup.waiting")
            }
        }
    }

    // MARK: - Started by AppLocalizer

    private var launched: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AppLocalizer started Claude Code in \(folderText) and asked:")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            promptText
            if viewModel.isConnected {
                connectedBox
                fromNowOn
            } else if let run = viewModel.testRun {
                ClaudeCodeRunStatusView(run: run, onShowOutput: { outputRunID = run.id }, onRetried: viewModel.useTestRun)
            } else {
                HStack(spacing: Spacing.small) {
                    Text(notStartedText)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Start Test") { Task { await viewModel.startTest() } }
                        .controlSize(.small)
                        .accessibilityIdentifier("assistantSetup.launch.startTest")
                }
                .padding(Spacing.medium)
                .modifier(Box())
            }
        }
    }

    /// Why there's no test run: no folder was chosen, or the helper isn't
    /// ready.
    private var notStartedText: String {
        guard let launcher = viewModel.launcher, !launcher.canStart else {
            return String(localized: "Claude Code didn’t start: it needs \(viewModel.appName)’s project folder.")
        }
        return String(localized: "Claude Code didn’t start. \(launcher.helper.title).")
    }

    private var folderText: String {
        viewModel.testRun?.displayDirectory ?? viewModel.projectFolder.map { ProjectFolderPath.abbreviated($0) } ?? String(localized: "the project folder")
    }

    private var fromNowOn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("From now on")
                .font(.callout.weight(.semibold))
            Text("""
            Ask, Suggest Everything, Autopilot, translations and the privacy scan start Claude Code from here. Copy Prompt \
            stays in each one’s menu.
            """)
            .font(.caption)
            .foregroundStyle(Palette.label2)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("assistantSetup.launch.fromNowOn")
    }

    // MARK: - Shared

    private var promptText: some View {
        Text(AssistantSetupViewModel.testPrompt)
            .font(.callout.monospaced())
            .textSelection(.enabled)
            .padding(Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
    }

    private var connectedBox: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Palette.positive)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Connected")
                    .font(.callout.weight(.semibold))
                Text(viewModel.connectedText)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(Box())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("assistantSetup.connected")
    }

    private var thingsToAskList: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.thingsToAsk.enumerated()), id: \.offset) { index, item in
                if index > 0 { Divider() }
                HStack(spacing: Spacing.small) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.prompt)
                            .font(.callout)
                        Text(item.detail)
                            .font(.caption2)
                            .foregroundStyle(Palette.label2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Copy") { Self.copy(item.prompt) }
                        .controlSize(.small)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, Spacing.xSmall)
            }
        }
        .modifier(Box())
    }

    private static let thingsToAsk: [(prompt: String, detail: String)] = [
        (
            String(localized: "Write What’s New for my next version from the commits since the last release"),
            String(localized: "Store Page · from git history")
        ),
        (String(localized: "Fill in App Review notes for my next version"), String(localized: "App Information · from the code")),
        (
            String(localized: "Scan this project for App Privacy and send the answers to AppLocalizer"),
            String(localized: "App Privacy · from SDKs and privacy manifests")
        ),
        (String(localized: "Suggest German keywords for my app"), String(localized: "Store Page · German")),
    ]

    private static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    /// The raised, outlined box the step's states sit in.
    private struct Box: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
        }
    }

    private struct OutputRun: Identifiable {
        let id: ClaudeCodeRun.ID
    }
}
