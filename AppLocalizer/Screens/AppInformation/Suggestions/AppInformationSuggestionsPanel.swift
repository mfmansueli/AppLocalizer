//
//  AppInformationSuggestionsPanel.swift
//  AppLocalizer
//

import SwiftUI

/// What sits above a page's sections (General, Age Rating, App Review) or
/// one device's Accessibility suggestions while there's something to say:
/// suggestions arriving, what only an assistant reading the code can answer,
/// and the card offering to set one up.
struct AppInformationSuggestionsPanel: View {
    @Bindable var viewModel: AppInformationViewModel
    let page: AppInformationPage
    let scope: SuggestionScope

    init(viewModel: AppInformationViewModel, page: AppInformationPage) {
        self.viewModel = viewModel
        self.page = page
        scope = .appInformation(page)
    }

    init(viewModel: AppInformationViewModel, scope: SuggestionScope) {
        self.viewModel = viewModel
        page = scope.page ?? .general
        self.scope = scope
    }

    var body: some View {
        if viewModel.showsSuggestions(on: page) {
            SuggestionsPanel(
                appID: viewModel.app.id,
                area: .appInformation,
                scopes: [scope],
                hidesCTA: $viewModel.hidesAssistantCTA,
                codeOnlyCount: viewModel.codeOnlyAnswerCount(in: scope),
                appName: viewModel.app.name
            )
        }
    }
}
