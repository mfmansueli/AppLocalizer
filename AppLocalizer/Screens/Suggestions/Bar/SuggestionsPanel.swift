//
//  SuggestionsPanel.swift
//  AppLocalizer
//

import SwiftUI

/// What sits above the fields of a Store Page language or an App Information
/// page, only when there's something to say: the banner while an assistant
/// sends suggestions or Suggest Everything receives, what only an assistant
/// that reads the code can answer, and the card offering to set one up.
struct SuggestionsPanel: View {
    let appID: StoreApp.ID
    let area: SuggestionArea
    /// The language, page or device it's above, for Suggest Everything's
    /// "Here: 2 of 3 arrived."
    let scopes: [SuggestionScope]
    @Binding var hidesCTA: Bool
    /// With an API key: how many answers here only an assistant that reads
    /// `appName`'s code can suggest.
    var codeOnlyCount = 0
    var appName = ""

    @Environment(MCPServerController.self) private var assistants
    @Environment(FieldSuggestionStore.self) private var suggestions
    @Environment(WorkspaceNavigator.self) private var navigator

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if let streamingRequest {
                SuggestionStreamingBanner(request: streamingRequest)
            }
            if let run {
                SuggestionRunBanner(run: run, hereText: run.hereText(in: scopes)) {
                    navigator.open(.overview)
                }
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
        }
    }

    private var status: AssistantStatus { assistants.assistantStatus }

    /// Suggest Everything for this app, while it receives.
    private var run: SuggestionRun? {
        guard let run = suggestions.run, run.appID == appID, run.isRunning else { return nil }
        return run
    }

    /// The request for this app and area, while suggestions arrive.
    private var streamingRequest: AssistantSuggestionRequest? {
        guard let request = suggestions.request, request.appID == appID, request.area == area, request.isReceiving else { return nil }
        return request
    }
}
