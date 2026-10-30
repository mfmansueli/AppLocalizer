//
//  AssistantSetupSheet.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// "Set Up Your AI Assistant", from the Assistant button, the overview and
/// the suggestion bars: how (an assistant over MCP, or an API key), then
/// that method's steps, with the step bars on top and Cancel, a note, Back
/// and Continue at the bottom.
struct AssistantSetupSheet: View {
    @State private var viewModel: AssistantSetupViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        assistants: MCPServerController,
        keyAssistant: KeyAssistantController,
        appName: String,
        method: AssistantSetupMethod? = nil,
        step: AssistantSetupStep? = nil
    ) {
        #if DEBUG
        let step = step ?? Self.debugStep
        let method = method ?? Self.debugMethod
        #endif
        _viewModel = State(initialValue: AssistantSetupViewModel(
            assistants: assistants,
            keyAssistant: keyAssistant,
            appName: appName,
            method: method,
            step: step
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 22)
                .padding(.top, Spacing.xLarge)
                .padding(.bottom, Spacing.small)
            ScrollView {
                content
                    .padding(.horizontal, 22)
                    .padding(.top, Spacing.xSmall)
                    .padding(.bottom, 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 300, maxHeight: 520)
            Divider()
            footer
                .padding(.horizontal, 22)
                .padding(.vertical, Spacing.medium)
        }
        .frame(width: 680)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assistantSetup.sheet")
        #if DEBUG
        .task {
            guard let key = Self.debugKey else { return }
            Self.debugKey = nil
            await viewModel.debugFill(key: key)
        }
        #endif
    }

    // MARK: - Header and footer

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Set Up Your AI Assistant")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Step \(viewModel.step.rawValue) of \(AssistantSetupStep.allCases.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("assistantSetup.stepCount")
            }
            HStack(alignment: .top, spacing: Spacing.small) {
                ForEach(AssistantSetupStep.allCases) { step in
                    VStack(alignment: .leading, spacing: 5) {
                        Capsule()
                            .fill(step <= viewModel.step ? Palette.accent : Palette.fill3)
                            .frame(height: 3)
                        Text(viewModel.stepTitles[step.rawValue - 1])
                            .font(.caption2.weight(step == viewModel.step ? .semibold : .regular))
                            .foregroundStyle(step == viewModel.step ? Palette.label : step < viewModel.step ? Palette.label2 : Palette.label3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(step == viewModel.step ? .isSelected : [])
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: Spacing.small) {
            Button("Cancel") {
                viewModel.cancel()
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            .accessibilityIdentifier("assistantSetup.cancel")
            Text(viewModel.footnote)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .frame(maxWidth: .infinity, alignment: .leading)
            if viewModel.canGoBack {
                Button("Back", action: viewModel.goBack)
                    .accessibilityIdentifier("assistantSetup.back")
            }
            Button(viewModel.continueTitle) {
                if viewModel.advance() {
                    AccessibilityNotification.Announcement(viewModel.finishedAnnouncement).post()
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(!viewModel.canContinue)
            .accessibilityIdentifier("assistantSetup.continue")
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var content: some View {
        switch (viewModel.method, viewModel.step) {
        case (_, .assistant): AssistantSetupMethodStep(viewModel: viewModel)
        case (.assistant, .server): serverStep
        case (.assistant, .snippet): snippetStep
        case (.assistant, .test): testStep
        case (.apiKey, .server): KeyAssistantSetupKeyStep(viewModel: viewModel.key)
        case (.apiKey, .snippet): KeyAssistantSetupContextStep(viewModel: viewModel.key)
        case (.apiKey, .test): KeyAssistantSetupTestStep(viewModel: viewModel.key)
        }
    }

    private var serverStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Toggle(isOn: Binding(get: { viewModel.isServerOn }, set: { viewModel.setServerOn($0) })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Local MCP server")
                            .font(.callout.weight(.semibold))
                        Text("Lets assistants on this Mac talk to AppLocalizer.")
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                    }
                }
                .toggleStyle(.switch)
                .padding(Spacing.medium)
                .accessibilityIdentifier("assistantSetup.server")
                Divider()
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    fact("network", String(localized: "Listens only on this Mac (\(viewModel.assistants.address)), and only while AppLocalizer is open."))
                    fact("lock", String(localized: "Your App Store Connect key stays in the Keychain. Assistants get results, never the key."))
                    fact("key", String(localized: "Each assistant gets its own token, which you can revoke in Settings → AI Assistants."))
                }
                .padding(Spacing.medium)
            }
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
            Text("What can assistants do?")
                .font(.headline)
                .padding(.top, Spacing.xxSmall)
            VStack(spacing: Spacing.xSmall) {
                AssistantSetupOptionRow(
                    title: String(localized: "Suggest only"),
                    detail: String(localized: "Suggestions wait here, marked with the assistant’s name, until you accept or dismiss them."),
                    isSelected: !viewModel.editsDrafts
                ) {
                    viewModel.editsDrafts = false
                }
                .accessibilityIdentifier("assistantSetup.suggestOnly")
                AssistantSetupOptionRow(
                    title: String(localized: "Suggest and edit drafts"),
                    detail: String(localized: """
                    The assistant can also change fields directly. Changes are marked with its name and stay unpushed \
                    until you review them.
                    """),
                    isSelected: viewModel.editsDrafts
                ) {
                    viewModel.editsDrafts = true
                }
                .accessibilityIdentifier("assistantSetup.editDrafts")
            }
            Text("Either way, nothing reaches App Store Connect until you push it in Review & Push.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
        }
    }

    private func fact(_ systemImage: String, _ text: String) -> some View {
        Label {
            Text(text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Palette.label2)
        }
    }

    private var snippetStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.kind.setupIntro)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Text(viewModel.snippet ?? "")
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .accessibilityIdentifier("assistantSetup.snippet")
            HStack(spacing: Spacing.small) {
                Button {
                    if let snippet = viewModel.copySnippet() { Self.copy(snippet) }
                } label: {
                    Label(viewModel.hasCopiedSnippet ? String(localized: "Copied") : viewModel.kind.copyTitle, systemImage: "doc.on.doc")
                }
                .accessibilityIdentifier("assistantSetup.copy")
                Text("Includes a new token just for \(viewModel.kind.title).")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .controlSize(.small)
            InlineMessage(text: viewModel.kind.setupNote, systemImage: "info.circle", tint: Palette.label2)
                .font(.caption)
        }
    }

    private var testStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Now ask \(viewModel.clientName) something that uses AppLocalizer:")
                .font(.callout)
            HStack(spacing: Spacing.small) {
                Text(AssistantSetupViewModel.testPrompt)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                    .padding(Spacing.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                Button("Copy") { Self.copy(AssistantSetupViewModel.testPrompt) }
                    .controlSize(.small)
            }
            if viewModel.isConnected {
                connectedBox
                Text("Things to ask next")
                    .font(.headline)
                    .padding(.top, Spacing.xxSmall)
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
                .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
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
                .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("assistantSetup.waiting")
            }
        }
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
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("assistantSetup.connected")
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
}
