//
//  TranslationSettingsTab.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → Translation: who translates (Apple Translation on this Mac,
/// an AI provider with its own API key, or the assistant connected through
/// MCP), the glossary of terms that stay as they are, the source locale and
/// the tone. Under the API key, whether it's saved and the vendor takes it.
struct TranslationSettingsTab: View {
    @Environment(TranslationPreferences.self) private var preferences
    @State private var keyStatus: AIProviderKeyStatusModel
    @State private var draftKey = ""
    @State private var keyErrorMessage: String?
    /// Bumped by saving a key and by Check Again, to check once more.
    @State private var checkRequests = 0
    @FocusState private var isKeyFocused: Bool

    init(keyStatus: AIProviderKeyStatusModel) {
        _keyStatus = State(initialValue: keyStatus)
    }

    var body: some View {
        @Bindable var preferences = preferences
        Form {
            Section("Provider") {
                TranslationProviderRow(provider: .appleTranslation, selection: $preferences.provider)
                TranslationProviderRow(provider: .aiProvider, selection: $preferences.provider) {
                    aiProviderControls
                }
                TranslationProviderRow(provider: .assistant, selection: $preferences.provider)
                if let keyErrorMessage {
                    InlineMessage.error(keyErrorMessage)
                }
            }
            Section("Glossary · never translated") {
                GlossaryEditor(glossary: $preferences.glossary)
                    .padding(.vertical, Spacing.xxSmall)
            }
            Section("Defaults") {
                Picker("Source locale", selection: $preferences.sourceLocaleCode) {
                    Text("Each app’s primary locale").tag(String?.none)
                    Divider()
                    ForEach(StoreLocaleCatalog.all) { locale in
                        Text(locale.name).tag(String?.some(locale.code))
                    }
                }
                .accessibilityIdentifier("settings.sourceLocale")
                Picker("Tone", selection: $preferences.glossary.tone) {
                    ForEach(TranslationTone.allCases) { Text($0.title).tag($0) }
                }
                .accessibilityIdentifier("settings.tone")
            }
        }
        .formStyle(.grouped)
        // A newer check (another vendor, a new key) cancels the one running.
        .task(id: KeyCheckID(vendor: preferences.vendor, request: checkRequests)) {
            await keyStatus.check(preferences)
        }
    }

    private var aiProviderControls: some View {
        @Bindable var preferences = preferences
        return VStack(alignment: .trailing, spacing: Spacing.xxSmall) {
            HStack(spacing: Spacing.small) {
                Picker("Provider", selection: $preferences.vendor) {
                    ForEach(AIProviderVendor.allCases) { Text($0.title).tag($0) }
                }
                .labelsHidden()
                .fixedSize()
                SecureField("API key", text: $draftKey, prompt: Text(preferences.hasAPIKey ? "••••••••••••••••••••" : "Paste an API key"))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .focused($isKeyFocused)
                    .onSubmit(saveKey)
                    .onChange(of: isKeyFocused) { _, focused in
                        if !focused { saveKey() }
                    }
                    .help(Text("Kept in this Mac’s Keychain"))
                    .accessibilityIdentifier("settings.apiKey")
            }
            AIProviderKeyStatusLine(status: keyStatus.status) { checkRequests += 1 }
        }
    }

    /// Saves a typed key; an untouched field keeps the saved one.
    private func saveKey() {
        guard !draftKey.isEmpty else { return }
        do {
            try preferences.saveAPIKey(draftKey)
            draftKey = ""
            keyErrorMessage = nil
            checkRequests += 1
        } catch {
            keyErrorMessage = error.localizedDescription
        }
    }

    private struct KeyCheckID: Hashable {
        let vendor: AIProviderVendor
        let request: Int
    }
}
