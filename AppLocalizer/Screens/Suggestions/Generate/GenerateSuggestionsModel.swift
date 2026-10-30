//
//  GenerateSuggestionsModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Generate Suggestions… with an API key: first what will be sent and about
/// how many tokens, then one request. The suggestions go in as a request
/// that's already complete, so the banner shows the total and the toast
/// follows; a request that finds nothing new ends with its own toast.
@MainActor
@Observable
final class GenerateSuggestionsModel {
    enum Phase: Hashable {
        /// Reading the project folder and the reviews.
        case preparing
        case ready
        case generating
        case failed(String)
    }

    enum Outcome: Hashable {
        /// They're in the store; the request's toast follows.
        case sent
        /// "Anthropic API found nothing new to suggest."
        case nothingNew(String)
        /// The popover stays open with why.
        case failed
        case cancelled
    }

    let keyAssistant: KeyAssistantController
    let generator: any KeyAssistantGenerating
    let suggestions: FieldSuggestionStore
    let appID: StoreApp.ID
    let area: SuggestionArea
    private(set) var plan: KeyAssistantPlan?
    private(set) var phase: Phase = .preparing

    init(
        keyAssistant: KeyAssistantController,
        generator: any KeyAssistantGenerating,
        suggestions: FieldSuggestionStore,
        appID: StoreApp.ID,
        area: SuggestionArea
    ) {
        self.keyAssistant = keyAssistant
        self.generator = generator
        self.suggestions = suggestions
        self.appID = appID
        self.area = area
    }

    // MARK: - Reading

    /// "Anthropic API".
    var client: String { keyAssistant.clientName ?? "" }

    /// "Generate with Anthropic API".
    var title: String { String(localized: "Generate with \(client)") }

    var intro: String {
        let vendor = keyAssistant.configuration?.vendor.title ?? client
        return String(localized: "AppLocalizer sends this to \(vendor), then shows the suggestions here. Nothing changes until you accept them.")
    }

    /// "About 9.4k tokens in, billed to your Anthropic account. Source
    /// code isn’t sent."
    var totalText: String? {
        guard let plan, let vendor = keyAssistant.configuration?.vendor else { return nil }
        return plan.totalText(vendor: vendor)
    }

    var canGenerate: Bool {
        guard plan != nil, keyAssistant.isReady else { return false }
        return switch phase {
        case .ready, .failed: true
        case .preparing, .generating: false
        }
    }

    var isGenerating: Bool { phase == .generating }

    // MARK: - Generating

    func prepare() async {
        phase = .preparing
        plan = await generator.keyAssistantPlan(using: keyAssistant)
        phase = plan == nil ? .failed(String(localized: "There’s nothing to send yet. Try again once the page has loaded.")) : .ready
    }

    func generate() async -> Outcome {
        guard canGenerate, let plan else { return .failed }
        let client = client
        phase = .generating
        let items: [KeyAssistantSuggestionItem]
        do {
            items = try await keyAssistant.generate(plan)
        } catch {
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                phase = .ready
                return .cancelled
            }
            phase = .failed(error.localizedDescription)
            return .failed
        }
        suggestions.beginRequest(appID: appID, area: area, client: client, prompt: plan.title)
        let count = generator.addGeneratedSuggestions(items, client: client)
        phase = .ready
        guard count > 0 else {
            suggestions.cancelRequest()
            return .nothingNew(String(localized: "\(client) found nothing new to suggest."))
        }
        suggestions.noteExpectedTotal(count, client: client, appID: appID)
        return .sent
    }
}
