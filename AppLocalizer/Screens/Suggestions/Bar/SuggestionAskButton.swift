//
//  SuggestionAskButton.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// "Ask Claude Code…" in a section's header, or Generate Suggestions… with
/// an API key, or Set Up Assistant…. AppLocalizer starts Claude Code itself
/// once its helper is saved (`ClaudeCodeLauncher`), and otherwise copies the
/// prompt to paste. It ends the request with a toast once the suggestions
/// stop coming or the run ends. While suggestions arrive the section's banner
/// says so and the button steps aside.
struct SuggestionAskButton: View {
    let appID: StoreApp.ID
    let area: SuggestionArea
    /// Set by the Assistant button's Ask for Suggestions…: asks once shown.
    @Binding var requestsAsk: Bool
    /// The text "Ask …" copies.
    let prompt: () -> String
    /// The page Generate Suggestions… works on with an API key; none where
    /// a key can't suggest anything.
    var generator: (any KeyAssistantGenerating)?
    /// Names the run when AppLocalizer starts Claude Code, and its project
    /// folder's Open panel.
    var appName = ""
    /// The assistant stopped sending: the section shows this in its toast.
    var onRequestFinished: (String) -> Void = { _ in }

    @Environment(MCPServerController.self) private var assistants
    @Environment(FieldSuggestionStore.self) private var suggestions
    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(KeyAssistantController.self) private var keyAssistant
    @Environment(ClaudeCodeLauncher.self) private var launcher
    @State private var showsPopover = false
    @State private var generate: GenerateSuggestionsModel?
    @State private var generation: Task<Void, Never>?

    var body: some View {
        // A stack, so the tasks below keep running while the button is away.
        ZStack {
            if streamingRequest == nil, run == nil {
                button
            }
        }
        .onChange(of: request?.isReceiving) {
            if request?.isReceiving == true { showsPopover = false }
        }
        .onChange(of: request == nil) {
            if request == nil { showsPopover = false }
        }
        .onChange(of: assistants.isWorking) {
            if !assistants.isWorking, streamingRequest != nil { finishRequest() }
        }
        .onChange(of: askRun?.phase) { runChanged() }
        .task(id: requestsAsk) {
            guard requestsAsk else { return }
            requestsAsk = false
            // The popover needs its button on screen first.
            try? await Task.sleep(for: .milliseconds(300))
            startAsking()
        }
        .task(id: request?.isComplete) {
            guard request?.isComplete == true else { return }
            // Long enough to read "4 of 4" before the toast.
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            finishRequest()
        }
    }

    private var button: some View {
        Button(status.askTitle, action: startAsking)
            .disabled(status.isReady && generator == nil)
            .accessibilityIdentifier("suggestions.ask")
            .popover(isPresented: $showsPopover, arrowEdge: .bottom) {
                if status.isReady, let generate {
                    GenerateSuggestionsPopover(model: generate, onGenerate: startGenerating) {
                        showsPopover = false
                        cancelGenerating()
                    }
                } else if let request {
                    AskAssistantPopover(request: request) {
                        Self.copy(request.prompt)
                    } onCancel: {
                        showsPopover = false
                        suggestions.cancelRequest()
                    }
                }
            }
    }

    private var status: AssistantStatus { assistants.assistantStatus }

    /// The request for this app and area, if one is open.
    private var request: AssistantSuggestionRequest? {
        guard let request = suggestions.request, request.appID == appID, request.area == area else { return nil }
        return request
    }

    /// Suggest Everything for this app, while it receives.
    private var run: SuggestionRun? {
        guard let run = suggestions.run, run.appID == appID, run.isRunning else { return nil }
        return run
    }

    private var streamingRequest: AssistantSuggestionRequest? {
        request?.isReceiving == true ? request : nil
    }

    private var askPurpose: ClaudeCodeRunPurpose { .ask(area: area.title) }

    /// The run AppLocalizer started for the open request.
    private var askRun: ClaudeCodeRun? {
        guard let request else { return nil }
        return launcher.latestRun(appID: appID, purpose: askPurpose, since: request.startedAt)
    }

    /// Asks the connected assistant, opens Generate Suggestions…, or setup.
    private func startAsking() {
        if status.isConnected {
            ask()
            showsPopover = true
        } else if status.isReady {
            guard generator != nil else { return }
            prepareGenerate()
            showsPopover = true
        } else {
            navigator.isAssistantSetupPresented = true
        }
    }

    /// Starts Claude Code when the helper is saved, else copies the prompt.
    private func ask() {
        guard case let .connected(client) = assistants.assistantStatus else { return }
        // Already asked and still going: the popover shows that run.
        if askRun?.isActive == true { return }
        let text = prompt()
        suggestions.beginRequest(appID: appID, area: area, client: client, prompt: text)
        guard launcher.canStart else {
            Self.copy(text)
            return
        }
        Task {
            guard await launcher.start(askPurpose, appID: appID, appName: appName, prompt: text) == nil else { return }
            // No folder chosen, so nothing was asked; or the helper went
            // away, so it's the paste after all.
            if launcher.canStart { suggestions.cancelRequest() } else { Self.copy(text) }
        }
    }

    /// The run ended: what it sent ends the request with the toast; a
    /// failure, or refused steps with nothing sent, stays for the popover
    /// to explain.
    private func runChanged() {
        guard let request, let run = askRun else { return }
        switch run.phase {
        case .finished where request.isReceiving, .stopped where request.isReceiving:
            finishRequest()
        case .finished where run.denials.isEmpty:
            suggestions.cancelRequest()
            onRequestFinished(String(localized: "\(request.client) finished without sending suggestions."))
        case .stopped:
            suggestions.cancelRequest()
        case .starting, .working, .failed, .finished:
            break
        }
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
                showsPopover = false
            case let .nothingNew(text):
                showsPopover = false
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
