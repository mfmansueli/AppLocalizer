//
//  KeyAssistantSettingsSection.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → AI Assistants' API key: Set Up… before there is one; then
/// the provider and model, the masked key, what each request may include,
/// whether translations use it too, Set Up Again… and Remove Key. It works
/// alongside an MCP assistant; while one is connected, that one suggests.
struct KeyAssistantSettingsSection: View {
    @Environment(KeyAssistantController.self) private var keyAssistant
    @Environment(MCPServerController.self) private var server
    @State private var isSettingUp = false
    @State private var isConfirmingRemove = false
    @State private var errorText: String?

    var body: some View {
        Section {
            if let configuration = keyAssistant.configuration {
                configured(configuration)
            } else {
                HStack {
                    SettingsRowLabel(
                        title: "API key",
                        caption: String(localized: """
                        Generate Store Page suggestions with your own key from Anthropic, OpenAI or Google Gemini, without \
                        an assistant. It doesn’t read code.
                        """)
                    )
                    Spacer()
                    Button("Set Up…") { isSettingUp = true }
                        .accessibilityIdentifier("settings.ai.key.setUp")
                }
            }
        } header: {
            Text("API key")
        } footer: {
            if let errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
            }
        }
        .sheet(isPresented: $isSettingUp) {
            AssistantSetupSheet(
                assistants: server,
                keyAssistant: keyAssistant,
                appName: String(localized: "your app"),
                method: .apiKey,
                step: .server
            )
        }
        .confirmationDialog("Remove the API key?", isPresented: $isConfirmingRemove) {
            Button("Remove Key", role: .destructive, action: keyAssistant.remove)
        } message: {
            Text("It’s deleted from the Keychain. Settings → Translation keeps its own copy.")
        }
    }

    @ViewBuilder
    private func configured(_ configuration: KeyAssistantConfiguration) -> some View {
        LabeledContent("Provider") {
            Text(configuration.vendor.apiName)
        }
        Picker("Model", selection: Binding(get: { configuration.model }, set: { model in keyAssistant.update { $0.model = model } })) {
            ForEach(models(configuration)) { model in
                Text(model.pickerTitle).tag(model)
            }
        }
        .accessibilityIdentifier("settings.ai.key.model")
        LabeledContent("Key") {
            Text(configuration.maskedKey)
                .font(.callout.monospaced())
                .accessibilityIdentifier("settings.ai.key.masked")
        }
        Toggle(isOn: Binding(get: { configuration.readsProjectFolder }, set: setReadsFolder)) {
            SettingsRowLabel(
                title: "Read the project folder",
                caption: configuration.projectFolderPath.map { String(localized: "Commit messages and CHANGELOG.md from \($0), never code.") }
                    ?? String(localized: "Commit messages and CHANGELOG.md, never code.")
            )
        }
        .accessibilityIdentifier("settings.ai.key.folder")
        if configuration.readsProjectFolder {
            Button("Choose Another Folder…") {
                if let url = ProjectFolderPicker.choose() { keyAssistant.setProjectFolder(url) }
            }
            .controlSize(.small)
        }
        Toggle(isOn: Binding(get: { configuration.readsReviews }, set: { isOn in keyAssistant.update { $0.readsReviews = isOn } })) {
            SettingsRowLabel(title: "Read customer reviews", caption: String(localized: "The latest App Store reviews, to learn what people praise."))
        }
        .accessibilityIdentifier("settings.ai.key.reviews")
        Toggle(isOn: Binding(get: { configuration.usesKeyForTranslations }, set: setUsesForTranslations)) {
            SettingsRowLabel(title: "Also use this key for translations", caption: String(localized: "Settings → Translation then uses it too."))
        }
        .accessibilityIdentifier("settings.ai.key.translations")
        HStack {
            Text(server.assistantStatus.isConnected
                ? String(localized: "While an MCP assistant is connected, it suggests instead of the key.")
                : String(localized: "The key goes only to \(configuration.vendor.title), with requests you confirm."))
                .font(.caption)
                .foregroundStyle(Palette.label2)
            Spacer()
            Button("Set Up Again…") { isSettingUp = true }
                .accessibilityIdentifier("settings.ai.key.setUpAgain")
            Button("Remove Key…", role: .destructive) { isConfirmingRemove = true }
                .accessibilityIdentifier("settings.ai.key.remove")
        }
        .controlSize(.small)
    }

    private func models(_ configuration: KeyAssistantConfiguration) -> [KeyAssistantModel] {
        let models = configuration.vendor.assistantModels(available: [configuration.model.id])
        return models.contains(configuration.model) ? models : [configuration.model] + models
    }

    private func setReadsFolder(_ isOn: Bool) {
        guard isOn else { return keyAssistant.update { $0.readsProjectFolder = false } }
        if keyAssistant.configuration?.projectFolderPath == nil {
            if let url = ProjectFolderPicker.choose() { keyAssistant.setProjectFolder(url) }
        } else {
            keyAssistant.update { $0.readsProjectFolder = true }
        }
    }

    private func setUsesForTranslations(_ isOn: Bool) {
        do {
            try keyAssistant.setUsesKeyForTranslations(isOn)
            errorText = nil
        } catch {
            errorText = String(localized: "Couldn’t save the key for translations: \(error.localizedDescription)")
        }
    }
}
