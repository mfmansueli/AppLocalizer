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
        guard case let .openAppInformationPage(page, privacyTab) = intent else { return false }
        self.page = page
        if let privacyTab { privacy.tab = privacyTab }
        return true
    }
}
