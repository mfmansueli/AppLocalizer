//
//  KeyAssistantController.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Suggestions from the person's own API key (Anthropic, OpenAI or Google
/// Gemini) instead of an assistant over MCP: the key's setup, Check Key and
/// the test request, and Generate Suggestions…. The key is in the Keychain
/// and goes only to its vendor, with each request; only what the person
/// allowed goes with it (App Store Connect's text always, the project
/// folder's commits and changelog, and reviews), never source code.
@MainActor
@Observable
final class KeyAssistantController {
    private(set) var configuration: KeyAssistantConfiguration?
    /// Newest first, at most five.
    private(set) var recentRequests: [KeyAssistantRequestLog] = []

    let service: any KeyAssistantService
    var projectFolderReader = ProjectFolderReader()
    #if DEBUG
    /// DEBUG scenes' commits and changelog, instead of reading the folder.
    var debugProjectFolder: ProjectFolderExcerpt?
    #endif
    private let secrets: any SecretStore
    private let defaults: UserDefaults?
    /// Settings → Translation, for "Also use this key for translations".
    private let translation: TranslationPreferences?

    /// nil `defaults` keeps everything in memory (DEBUG scenes, tests).
    init(service: any KeyAssistantService, secrets: any SecretStore, defaults: UserDefaults? = .standard, translation: TranslationPreferences? = nil) {
        self.service = service
        self.secrets = secrets
        self.defaults = defaults
        self.translation = translation
        let saved = defaults?.data(forKey: Key.configuration).flatMap { try? JSONDecoder().decode(KeyAssistantConfiguration.self, from: $0) }
        // A key that's gone from the Keychain isn't set up any more.
        if let saved, ((try? secrets.secret(named: saved.vendor.assistantSecretName)) ?? nil) != nil {
            configuration = saved
        }
        recentRequests = defaults?.data(forKey: Key.recentRequests)
            .flatMap { try? JSONDecoder().decode([KeyAssistantRequestLog].self, from: $0) } ?? []
    }

    var isReady: Bool { configuration != nil }

    /// "Anthropic API", how its suggestions are tagged.
    var clientName: String? { configuration?.vendor.apiName }

    /// "Claude Sonnet 5.5 · key in the Keychain · reads commits and
    /// CHANGELOG.md, not code".
    var summary: String? {
        guard let configuration else { return nil }
        let reads = configuration.readsProjectFolder
            ? String(localized: "reads commits and CHANGELOG.md, not code")
            : String(localized: "doesn’t read code")
        return String(localized: "\(configuration.model.name) · key in the Keychain · \(reads)")
    }

    // MARK: - Setting up

    /// The saved key, when setup opens again.
    func savedKey() -> String? {
        guard let configuration else { return nil }
        return (try? secrets.secret(named: configuration.vendor.assistantSecretName)) ?? nil
    }

    /// Check Key: the models the key can use, or why it can't be used.
    func check(_ key: String, vendor: AIProviderVendor) async throws -> [KeyAssistantModel] {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw KeyAssistantKeyError.missing }
        return try await vendor.assistantModels(available: service.modelIDs(vendor: vendor, apiKey: key))
    }

    /// The setup's last step: one subtitle for `appName`, about 400 tokens.
    func test(key: String, vendor: AIProviderVendor, model: KeyAssistantModel, appName: String) async throws -> KeyAssistantAnswer {
        var answer = try await service.complete(
            AIProviderCompletion(
                system: "You write App Store subtitles.",
                user: "Write one App Store subtitle for \(appName), at most 30 characters. Answer with the subtitle only.",
                model: model.id,
                maxTokens: 2000
            ),
            vendor: vendor,
            apiKey: key.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        answer.text = answer.text.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'").union(.whitespacesAndNewlines))
        noteRequest(String(localized: "Test request"), tokens: answer.tokens ?? 400)
        return answer
    }

    /// Done or Finish Without Testing: the key goes in the Keychain, and
    /// with "Also use this key for translations" Settings → Translation
    /// uses it too.
    func save(_ configuration: KeyAssistantConfiguration, key: String) throws {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if let old = self.configuration, old.vendor != configuration.vendor {
            try secrets.setSecret(nil, named: old.vendor.assistantSecretName)
        }
        try secrets.setSecret(key, named: configuration.vendor.assistantSecretName)
        var configuration = configuration
        configuration.keySuffix = String(key.suffix(4))
        if configuration.usesKeyForTranslations, let translation {
            translation.vendor = configuration.vendor
            try translation.saveAPIKey(key)
            translation.provider = .aiProvider
        }
        self.configuration = configuration
        persist()
    }

    /// Settings → AI Assistants' switches and model picker.
    func update(_ change: (inout KeyAssistantConfiguration) -> Void) {
        guard var configuration else { return }
        change(&configuration)
        self.configuration = configuration
        persist()
    }

    /// Settings → AI Assistants' Choose…, or nil to stop reading it.
    func setProjectFolder(_ url: URL?) {
        update { configuration in
            configuration.projectFolderPath = url.map { ProjectFolderPath.abbreviated($0.path) }
            configuration.projectFolderBookmark = url.flatMap(ProjectFolderPicker.bookmark)
            configuration.readsProjectFolder = url != nil
        }
    }

    /// "Also use this key for translations": on, Settings → Translation
    /// uses the key; off leaves Translation's own copy as it is.
    func setUsesKeyForTranslations(_ isOn: Bool) throws {
        guard let configuration else { return }
        if isOn, let translation, let key = try secrets.secret(named: configuration.vendor.assistantSecretName) {
            translation.vendor = configuration.vendor
            try translation.saveAPIKey(key)
            translation.provider = .aiProvider
        }
        update { $0.usesKeyForTranslations = isOn }
    }

    /// Remove Key: Settings → Translation keeps its own copy.
    func remove() {
        if let configuration { try? secrets.setSecret(nil, named: configuration.vendor.assistantSecretName) }
        configuration = nil
        recentRequests = []
        persist()
    }

    // MARK: - Generating

    /// What the project folder adds to a request, read with the access the
    /// person granted; nil when it isn't allowed.
    func readProjectFolder(version: String?) async -> (excerpt: ProjectFolderExcerpt, path: String)? {
        guard let configuration, configuration.readsProjectFolder, let path = configuration.projectFolderPath else { return nil }
        #if DEBUG
        if let debugProjectFolder { return (debugProjectFolder, path) }
        #endif
        var isStale = false
        let url = configuration.projectFolderBookmark.flatMap {
            try? URL(resolvingBookmarkData: $0, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        } ?? URL(filePath: ProjectFolderPath.expanded(path))
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
        return await (projectFolderReader.read(url, version: version), path)
    }

    /// Sends the plan and reads the suggestions out of the answer.
    func generate(_ plan: KeyAssistantPlan) async throws -> [KeyAssistantSuggestionItem] {
        guard let configuration, let key = try secrets.secret(named: configuration.vendor.assistantSecretName) else {
            throw KeyAssistantKeyError.missing
        }
        let answer = try await service.complete(
            AIProviderCompletion(system: plan.system, user: plan.user, model: configuration.model.id, maxTokens: 16000, wantsJSON: true),
            vendor: configuration.vendor,
            apiKey: key
        )
        noteRequest(plan.title, tokens: answer.tokens ?? plan.totalTokens)
        return try KeyAssistantAnswerParser.items(from: answer.text, vendor: configuration.vendor)
    }

    // MARK: - Helpers

    /// Recent Requests, newest first.
    func noteRequest(_ title: String, tokens: Int, at date: Date = .now) {
        recentRequests.insert(KeyAssistantRequestLog(title: title, tokens: tokens, date: date), at: 0)
        recentRequests = Array(recentRequests.prefix(5))
        defaults?.set(try? JSONEncoder().encode(recentRequests), forKey: Key.recentRequests)
    }

    private func persist() {
        defaults?.set(configuration.flatMap { try? JSONEncoder().encode($0) }, forKey: Key.configuration)
        defaults?.set(try? JSONEncoder().encode(recentRequests), forKey: Key.recentRequests)
    }

    private enum Key {
        static let configuration = "keyAssistantConfiguration"
        static let recentRequests = "keyAssistantRecentRequests"
    }
}
