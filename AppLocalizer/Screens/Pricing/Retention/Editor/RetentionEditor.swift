//
//  RetentionEditor.swift
//  AppLocalizer
//

import SwiftUI

/// The selected message: its name and state, the subscriptions that show
/// it, what it shows, the language being edited with its header and
/// message, and Translate All and Add to Review & Push.
struct RetentionEditor: View {
    let model: RetentionModel
    let message: RetentionMessage

    var body: some View {
        Card(padding: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                nameRow
                RetentionSubscriptionChips(model: model, message: message)
                RetentionKindSection(model: model, message: message)
                Divider()
                RetentionLanguagePicker(model: model, message: message)
                if model.showsAllLanguages {
                    RetentionLanguagesTable(model: model, message: message)
                }
                RetentionTextFields(model: model)
                RetentionTooLongBanner(model: model, message: message)
                if let note = model.sourceNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("retention.sourceNote")
                }
                Divider()
                RetentionEditorFooter(model: model, message: message)
            }
        }
        .accessibilityIdentifier("retention.editor")
    }

    private var nameRow: some View {
        let status = model.status(of: message)
        return HStack(spacing: Spacing.small) {
            TextField(
                "Name",
                text: Binding(get: { message.referenceName }, set: model.setName),
                prompt: Text("Only you see the name")
            )
            .textFieldStyle(.roundedBorder)
            .font(.title3.weight(.semibold))
            .disabled(!model.canRename)
            .help(model.canRename
                ? String(localized: "Only you see it, in App Store Connect. It can’t change once the message is pushed.")
                : String(localized: "App Store Connect keeps a message’s name; only you see it."))
            .accessibilityLabel("Message name")
            .accessibilityIdentifier("retention.name")
            Pill(text: status.title, style: status.pillStyle)
                .help(status.help)
                .accessibilityIdentifier("retention.status")
        }
    }
}
