//
//  WorkspaceToast.swift
//  AppLocalizer
//

import Foundation

/// A toast the whole window shows, over any section: Suggest Everything's
/// total when it finishes (Review by Area opens Overview), its Accept All
/// with Undo, and the offer to start it once setup connected an assistant.
struct WorkspaceToast: Identifiable, Hashable, Sendable {
    enum Action: Hashable, Sendable {
        /// "Review by Area": the run's app's Overview.
        case openOverview(StoreApp.ID)
        /// "Suggest Everything".
        case suggestEverything
    }

    var message: ToastMessage
    var action: Action?
    /// What Undo puts back after the card's Accept All.
    var undo: SuggestionRunAcceptance.Undo?

    var id: UUID { message.id }

    /// "Claude Code sent 18 suggestions: Store Page 5 · General 1 · …"
    static func finished(_ run: SuggestionRun) -> WorkspaceToast {
        WorkspaceToast(
            message: ToastMessage(text: run.finishedText, actionTitle: run.received > 0 ? String(localized: "Review by Area") : nil),
            action: run.received > 0 ? .openOverview(run.appID) : nil
        )
    }

    /// The card's Accept All (n).
    static func accepted(_ count: Int, undo: SuggestionRunAcceptance.Undo) -> WorkspaceToast {
        let text = count == 1
            ? String(localized: "Accepted 1 suggestion. Nothing is pushed yet.")
            : String(localized: "Accepted \(count) suggestions. Nothing is pushed yet.")
        return WorkspaceToast(message: ToastMessage(text: text, canUndo: true), undo: undo)
    }

    /// Setup opened from Suggest Everything… ended with `client` connected.
    static func connected(_ client: String) -> WorkspaceToast {
        WorkspaceToast(
            message: ToastMessage(text: String(localized: "\(client) is connected."), actionTitle: String(localized: "Suggest Everything")),
            action: .suggestEverything
        )
    }
}
