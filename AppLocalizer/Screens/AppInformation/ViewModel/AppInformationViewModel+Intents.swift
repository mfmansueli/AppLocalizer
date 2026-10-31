//
//  AppInformationViewModel+Intents.swift
//  AppLocalizer
//

import Foundation

/// Workspace intents meant for App Information.
extension AppInformationViewModel {
    /// Opens the page (and App Privacy's tab) an intent asks for. Returns
    /// whether it did, so the caller consumes it.
    func handle(_ intent: WorkspaceIntent) -> Bool {
        switch intent {
        case let .openAppInformationPage(page, privacyTab):
            self.page = page
            if let privacyTab { privacy.tab = privacyTab }
            return true
        case .reviewFieldSuggestions(.appInformation):
            openSuggestions()
            return true
        case let .reviewPageSuggestions(page):
            openSuggestions(on: page)
            return true
        case .askForSuggestions(.appInformation):
            openSuggestions()
            requestsAsk = true
            return true
        default:
            return false
        }
    }
}
