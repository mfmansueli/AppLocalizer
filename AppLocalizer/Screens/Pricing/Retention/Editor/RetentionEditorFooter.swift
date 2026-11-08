//
//  RetentionEditorFooter.swift
//  AppLocalizer
//

import SwiftUI

/// How many languages are ready, Translate All, Add to Review & Push, and
/// what happens after the push.
struct RetentionEditorFooter: View {
    let model: RetentionModel
    let message: RetentionMessage

    @Environment(TranslationPreferences.self) private var preferences

    var body: some View {
        let isQueued = model.isQueued(message)
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text(model.languagesSummary(of: message))
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("retention.summary")
                translateButton
            }
            Group {
                if isQueued {
                    Button("✓ In Review & Push", action: model.toggleQueue)
                        .buttonStyle(.bordered)
                } else {
                    Button("Add to Review & Push", action: model.toggleQueue)
                        .buttonStyle(.borderedProminent)
                        .disabled(!model.hasChangesToQueue)
                }
            }
            .help(queueHelp(isQueued: isQueued))
            .accessibilityIdentifier("retention.queue")
            if let notice = model.notice {
                Text(notice)
                    .font(.caption)
                    .foregroundStyle(Palette.label)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("retention.notice")
            }
            Text("After you push, Apple reviews the message and the offers before subscribers see them. Test it by canceling a sandbox subscription.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var translateButton: some View {
        if model.isTranslating {
            HStack(spacing: Spacing.xSmall) {
                ProgressView().controlSize(.small)
                Text("Translating…").font(.callout)
            }
        } else {
            let done = model.languagesToTranslate(in: message).isEmpty && message.text(for: model.sourceLocale.code).isComplete
            Button(done ? String(localized: "Translated") : String(localized: "Translate All"), action: translate)
                .disabled(!model.canTranslate)
                .help(done
                    ? String(localized: "Every language has its words. Change the \(model.sourceLocale.name) ones and Translate All again.")
                    : String(localized: "Translates the header and message from \(model.sourceLocale.name) with \(preferences.provider.title)"))
                .accessibilityIdentifier("retention.translateAll")
        }
    }

    private func translate() {
        let aiTranslator = preferences.provider == .aiProvider ? preferences.aiProviderSetup().makeTranslator(preferences.glossary.tone) : nil
        let translator = aiTranslator ?? model.services.translator
        let protector = preferences.glossary.protector
        Task { await model.translateAll(with: translator, protector: protector) }
    }

    private func queueHelp(isQueued: Bool) -> String {
        if isQueued { return String(localized: "Takes it out of Review & Push; your edits stay here") }
        if !model.hasChangesToQueue { return String(localized: "Nothing changed since App Store Connect’s") }
        return model.problems.first?.message ?? String(localized: "Waits in Review & Push; it goes to App Review when you push")
    }
}
