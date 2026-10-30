//
//  SuggestionsPanel.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// What sits above the fields of a Store Page language or an App
/// Information page: the suggestion bar, the banner while an assistant
/// sends suggestions, the card offering to set one up, and "No suggestions
/// for …". It runs "Ask Claude Code…" (copying the prompt, since
/// AppLocalizer can't start the assistant) and ends the request with a
/// toast once the suggestions stop coming. With an API key it runs
/// Generate Suggestions… where there's a `generator`, and says what only an
/// assistant that reads the code can answer.
struct SuggestionsPanel: View {
    let appID: StoreApp.ID
    let area: SuggestionArea
    /// "German" or "App Review".
    let scopeTitle: String
    let model: SuggestionBarModel
    @Binding var filter: SuggestionSourceFilter
    @Binding var showsOnlyFields: Bool
    @Binding var hidesCTA: Bool
    /// Set by the Assistant button's Ask for Suggestions…: asks once shown.
    @Binding var requestsAsk: Bool
    /// The text "Ask …" copies.
    let prompt: () -> String
    /// "Only fields with suggestions or changes", where there are fields.
    var showsFieldsToggle = true
    /// The page Generate Suggestions… works on with an API key; none where
    /// a key can't suggest anything.
    var generator: (any KeyAssistantGenerating)?
    /// With an API key: how many answers here only an assistant that reads
    /// `appName`'s code can suggest.
    var codeOnlyCount = 0
    var appName = ""
    var onDismissAll: () -> Void = {}
    var onAcceptAll: () -> Void = {}
    var onAcceptEverywhere: () -> Void = {}
    var onRestore: () -> Void = {}
    /// The assistant stopped sending: the section shows this in its toast.
    var onRequestFinished: (String) -> Void = { _ in }

    @Environment(MCPServerController.self) private var assistants
    @Environment(FieldSuggestionStore.self) private var suggestions
    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(KeyAssistantController.self) private var keyAssistant
    @State private var showsAskPopover = false
    @State private var generate: GenerateSuggestionsModel?
    @State private var generation: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SuggestionBar(
                model: model,
                status: status,
                filter: $filter,
                showsOnlyFields: $showsOnlyFields,
                showsAskPopover: $showsAskPopover,
                showsFieldsToggle: showsFieldsToggle,
                isStreaming: streamingRequest != nil,
                askRequest: request,
                generate: generate,
                canAsk: !status.isReady || generator != nil,
                onAsk: ask,
                onPrepareGenerate: prepareGenerate,
                onGenerate: startGenerating,
                onCancelGenerate: cancelGenerating,
                onSetUp: { navigator.isAssistantSetupPresented = true },
                onCopyPromptAgain: { if let request { Self.copy(request.prompt) } },
                onCancelAsk: { suggestions.cancelRequest() },
                onDismissAll: onDismissAll,
                onAcceptAll: onAcceptAll,
                onAcceptEverywhere: onAcceptEverywhere,
                onRestore: onRestore
            )
            if let streamingRequest {
                SuggestionStreamingBanner(request: streamingRequest)
            }
            if status.isReady, codeOnlyCount > 0 {
                KeyAssistantCodeNote(count: codeOnlyCount, appName: appName) {
                    navigator.assistantSetupMethod = .assistant
                    navigator.isAssistantSetupPresented = true
                }
            }
            if !status.canSuggest, !hidesCTA {
                AssistantSuggestionCTA(area: area, status: status) {
                    hidesCTA = true
                } onSetUp: {
                    navigator.isAssistantSetupPresented = true
                }
            }
            if model.totalCount == 0, streamingRequest == nil {
                SuggestionsEmptyNote(scopeTitle: scopeTitle, area: area, status: status)
            }
        }
        .onChange(of: assistants.isWorking) {
            if !assistants.isWorking, streamingRequest != nil { finishRequest() }
        }
        .task(id: requestsAsk) {
            guard requestsAsk else { return }
            requestsAsk = false
            // The popover needs its button on screen first.
            try? await Task.sleep(for: .milliseconds(300))
            if status.isConnected {
                ask()
                showsAskPopover = true
            } else if status.isReady {
                guard generator != nil else { return }
                prepareGenerate()
                showsAskPopover = true
            } else {
                navigator.isAssistantSetupPresented = true
            }
        }
        .task(id: request?.isComplete) {
            guard request?.isComplete == true else { return }
            // Long enough to read "4 of 4" before the toast.
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            finishRequest()
        }
    }

    private var status: AssistantStatus { assistants.assistantStatus }

    /// The request for this app and area, if one is open.
    private var request: AssistantSuggestionRequest? {
        guard let request = suggestions.request, request.appID == appID, request.area == area else { return nil }
        return request
    }

    private var streamingRequest: AssistantSuggestionRequest? {
        request?.isReceiving == true ? request : nil
    }

    private func ask() {
        guard case let .connected(client) = assistants.assistantStatus else { return }
        let text = prompt()
        Self.copy(text)
        suggestions.beginRequest(appID: appID, area: area, client: client, prompt: text)
    }

    /// Opens Generate Suggestions… on what will be sent; one already
    /// waiting for its answer stays.
    private func prepareGenerate() {
        guard generate?.isGenerating != true, let generator else { return }
        let model = GenerateSuggestionsModel(keyAssistant: keyAssistant, generator: generator, suggestions: suggestions, appID: appID, area: area)
        generate = model
        Task { await model.prepare() }
    }

    private func startGenerating() {
        guard let generate else { return }
        generation = Task {
            switch await generate.generate() {
            case .sent, .cancelled:
                showsAskPopover = false
            case let .nothingNew(text):
                showsAskPopover = false
                onRequestFinished(text)
            case .failed:
                break
            }
        }
    }

    private func cancelGenerating() {
        generation?.cancel()
        generation = nil
    }

    private func finishRequest() {
        guard let finished = suggestions.finishRequest(), finished.isReceiving else { return }
        onRequestFinished(finished.finishedText)
    }

    private static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
