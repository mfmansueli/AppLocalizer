//
//  TranslateCaptionsSheet.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// "Translate missing captions": the provider, Settings' tone and terms
/// not to translate (read-only here), and the locales with how many empty
/// captions each. Translate closes the sheet and runs the batch in the
/// progress banner. With the assistant as provider, it hands over a prompt
/// and waits for proposals instead.
struct TranslateCaptionsSheet: View {
    let viewModel: ScreenshotsViewModel
    let translation: CaptionTranslationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(MCPServerController.self) private var assistants
    @Environment(TranslationPreferences.self) private var preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Translate missing captions")
                    .font(.title2.weight(.semibold))
                Text("\(translation.selectedPlan.summary) Uses the provider, glossary and tone from Settings → Translation.")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("screenshots.captions.translateSheet.summary")
            }
            .padding([.horizontal, .top], Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    providers
                    setup
                    if translation.provider != .assistant {
                        CaptionTranslationGlossarySummary(glossary: translation.glossary)
                        availabilityMessages
                        CaptionTranslationLocaleList(translation: translation)
                        Text(footnote)
                            .font(.caption2)
                            .foregroundStyle(Palette.label2)
                    }
                }
                .padding(.horizontal, Spacing.xLarge)
                .padding(.bottom, Spacing.medium)
            }
            Divider()
            buttons
                .padding(Spacing.large)
        }
        .frame(width: 620, height: 560)
        .task { await translation.checkAvailability() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.captions.translateSheet")
    }

    private var footnote: String {
        String(localized: """
        Each caption is measured as it arrives. Ones that don’t fit are flagged, never cut. \
        Accepted text stays tagged “machine-translated” until someone reviews it.
        """)
    }

    private var providers: some View {
        VStack(spacing: 0) {
            ForEach(TranslationProvider.allCases) { provider in
                TranslateProviderRow(
                    provider: provider,
                    isSelected: translation.provider == provider,
                    title: provider.captionTitle(vendor: preferences.vendor),
                    detail: provider.captionDetail,
                    identifierPrefix: "screenshots.captions.translate"
                ) {
                    translation.provider = provider
                }
                if provider != TranslationProvider.allCases.last {
                    Divider()
                }
            }
        }
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Translation provider"))
    }

    /// The assistant's prompt, or what the provider needs first.
    @ViewBuilder
    private var setup: some View {
        if translation.provider == .assistant, assistants.isRunning {
            AssistantTranslatePanel(
                slashCommand: assistantPrompt.slashCommand,
                request: assistantPrompt.text,
                explanation: String(
                    localized: "Paste this into \(assistantName). Its captions appear in the table as proposals, tagged with who proposed them, and wait for you in Review & Push."
                ),
                clientName: assistantName,
                isCopied: translation.isAssistantPromptCopied,
                identifierPrefix: "screenshots.captions.translate"
            )
        } else if let message = translation.setupMessage {
            Banner(kind: .warning, title: message, isInline: true) {
                SettingsLink {
                    Text("Open Settings…")
                }
            }
            .accessibilityIdentifier("screenshots.captions.translate.setup")
        }
    }

    @ViewBuilder
    private var availabilityMessages: some View {
        if translation.provider == .appleTranslation {
            let needed = translation.localesNeedingDownload
            if !needed.isEmpty {
                HStack(spacing: Spacing.small) {
                    InlineMessage.warning(
                        String(localized: "Apple Translation needs to download \(ListFormatter.localizedString(byJoining: needed.map(\.name))) first.")
                    )
                    Spacer(minLength: Spacing.small)
                    LanguageDownloadButton(source: translation.plan.sourceLocale, targets: needed) {
                        await translation.checkAvailability()
                    }
                }
                .accessibilityIdentifier("screenshots.captions.translate.download")
            }
            let unsupported = translation.unsupportedLocales
            if !unsupported.isEmpty {
                InlineMessage.error(
                    String(localized: "Apple Translation can’t translate into \(ListFormatter.localizedString(byJoining: unsupported.map(\.name))).")
                )
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: Spacing.small) {
            Spacer()
            Button("Cancel", role: .cancel) { dismiss() }
                .keyboardShortcut(.cancelAction)
            if translation.provider == .assistant {
                Button(translation.isAssistantPromptCopied ? "Waiting for \(assistantName)…" : "Copy Prompt", action: copyAssistantPrompt)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!assistants.isRunning)
                    .accessibilityIdentifier("screenshots.captions.translate.copyPrompt")
            } else {
                Button(translation.startTitle) {
                    translation.start()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!translation.canStart)
                .accessibilityIdentifier("screenshots.captions.translate.start")
            }
        }
    }

    // MARK: - Assistant

    private var assistantPrompt: CaptionAssistantPrompt {
        CaptionAssistantPrompt(
            appName: viewModel.app.name,
            versionString: viewModel.context.version.versionString,
            glossary: translation.glossary
        )
    }

    /// The assistant that's connected, else the first paired one.
    private var assistantClient: MCPPairedClient? {
        assistants.connectedClients.first ?? assistants.pairedClients.first
    }

    private var assistantName: String {
        assistantClient?.name ?? String(localized: "your assistant")
    }

    /// Claude Code takes the slash command; other clients the request in
    /// words.
    private func copyAssistantPrompt() {
        let prompt = assistantPrompt
        let text = assistantClient?.kind == .claudeCode ? prompt.slashCommand : prompt.text
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        translation.isAssistantPromptCopied = true
    }
}
