//
//  AppInformationSuggestionsPanel.swift
//  AppLocalizer
//

import SwiftUI

/// The suggestion bar and its cards above a page's sections (General, Age
/// Rating, App Review) or one device's Accessibility suggestions, with the
/// scope's own Accept All, Dismiss All and Restore.
struct AppInformationSuggestionsPanel: View {
    @Bindable var viewModel: AppInformationViewModel
    let page: AppInformationPage
    let scope: SuggestionScope
    /// Accessibility lists only what's suggested, so it has no "Only
    /// fields…" toggle.
    var showsFieldsToggle = true

    @Environment(MCPServerController.self) private var assistants

    init(viewModel: AppInformationViewModel, page: AppInformationPage) {
        self.viewModel = viewModel
        self.page = page
        scope = .appInformation(page)
    }

    init(viewModel: AppInformationViewModel, scope: SuggestionScope, showsFieldsToggle: Bool = true) {
        self.viewModel = viewModel
        page = scope.page ?? .general
        self.scope = scope
        self.showsFieldsToggle = showsFieldsToggle
    }

    var body: some View {
        if viewModel.showsSuggestions(on: page) {
            SuggestionsPanel(
                appID: viewModel.app.id,
                area: .appInformation,
                scopeTitle: scope.title,
                model: viewModel.suggestionBar(for: scope, assistant: assistants.assistantStatus.clientName),
                filter: $viewModel.suggestionFilter,
                showsOnlyFields: $viewModel.showsOnlySuggestedFields,
                hidesCTA: $viewModel.hidesAssistantCTA,
                requestsAsk: $viewModel.requestsAsk,
                prompt: viewModel.suggestionPrompt,
                showsFieldsToggle: showsFieldsToggle,
                codeOnlyCount: viewModel.codeOnlyAnswerCount(in: scope),
                appName: viewModel.app.name,
                onDismissAll: { viewModel.dismissAllSuggestions(in: scope) },
                onAcceptAll: { viewModel.acceptAllSuggestions(in: scope) },
                onRestore: { viewModel.restoreDismissedSuggestions(in: scope) },
                onRequestFinished: { viewModel.suggestionToast = ToastMessage(text: $0) }
            )
        }
    }
}
