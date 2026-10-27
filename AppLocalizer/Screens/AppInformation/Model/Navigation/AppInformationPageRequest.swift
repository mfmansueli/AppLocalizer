//
//  AppInformationPageRequest.swift
//  AppLocalizer
//

import Foundation

/// The page App Information should open on next, asked for by another part
/// of the window: the overview's "Open App Privacy" and "Open Privacy
/// URLs". `WorkspaceIntent` has no case for a page, so the overview card
/// leaves the request here right before it opens the section, and the
/// section takes it as it opens.
@MainActor
final class AppInformationPageRequest {
    static let shared = AppInformationPageRequest()

    private var pending: (page: AppInformationPage, tab: AppPrivacyTab?)?

    func request(_ page: AppInformationPage, tab: AppPrivacyTab? = nil) {
        pending = (page, tab)
    }

    /// The page asked for, once.
    func take() -> (page: AppInformationPage, tab: AppPrivacyTab?)? {
        defer { pending = nil }
        return pending
    }
}
