//
//  WorkspaceSheet.swift
//  AppLocalizer
//

import Foundation

/// The window-wide sheets the toolbar opens.
enum WorkspaceSheet: Hashable, Sendable {
    case review
    /// Review & Push on every app's proposals from one assistant, as the
    /// toolbar indicator's "Review Proposals…" opens it.
    case proposals(client: String)
    case activity
    /// "Set Up Your AI Assistant".
    case assistantSetup
}
