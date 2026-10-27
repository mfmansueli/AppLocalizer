//
//  WorkspaceNavigator.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The main window's navigation state: which section shows, the sheets the
/// toolbar opens, and a pending intent for the section to act on. Shared
/// through the environment so menus, quick actions and sections can steer
/// the window.
@MainActor
@Observable
final class WorkspaceNavigator {
    var section: AppWorkspaceSection
    /// Review & Push (⇧⌘P).
    var isReviewPresented = false
    /// The source Review & Push opens filtered to, e.g. one assistant's
    /// proposals; cleared when it closes.
    var reviewSourceFilter: ChangeSourceFilter?
    /// Activity history (the toolbar clock).
    var isActivityPresented = false
    /// Set by Activity's "Restore Previous Values": Review & Push opens once
    /// Activity has closed (macOS shows one sheet at a time).
    var opensReviewAfterActivity = false
    /// Screenshots' Template tab is showing: the sidebar hides until it
    /// isn't.
    var hidesSidebar = false
    /// What the current section should do next; nil when nothing is pending.
    private(set) var intent: WorkspaceIntent?
    /// The app to select first, e.g. for Show in Captions on another app's
    /// render; the main window selects it and clears it.
    private(set) var requestedAppID: StoreApp.ID?
    /// Bumped by Refresh (⌘R). The library and every section reload when it
    /// changes (`.onChange(of: navigator.refreshCount)`).
    private(set) var refreshCount = 0

    init(section: AppWorkspaceSection = .overview) {
        self.section = section
    }

    /// Switches to `section` (of `appID` when given) and leaves `intent`
    /// for it to handle.
    func open(_ section: AppWorkspaceSection, intent: WorkspaceIntent? = nil, appID: StoreApp.ID? = nil) {
        self.section = section
        self.intent = intent
        requestedAppID = appID
    }

    /// Asks the current section to do something without switching.
    func send(_ intent: WorkspaceIntent) {
        self.intent = intent
    }

    /// Opens Review & Push on every app's proposals from `client`, or every
    /// change when it's nil.
    func reviewProposals(from client: String?) {
        reviewSourceFilter = client.map(ChangeSourceFilter.assistant)
        isReviewPresented = true
    }

    /// Called when Review & Push closed.
    func reviewDidClose() {
        reviewSourceFilter = nil
    }

    /// Closes Activity and opens Review & Push after it.
    func showReviewAfterActivity() {
        opensReviewAfterActivity = true
        isActivityPresented = false
    }

    /// Called when Activity closed.
    func activityDidClose() {
        guard opensReviewAfterActivity else { return }
        opensReviewAfterActivity = false
        isReviewPresented = true
    }

    /// Reloads everything from App Store Connect.
    func refresh() {
        refreshCount += 1
    }

    /// Called by the main window once it has selected `requestedAppID`.
    func consumeAppRequest() {
        requestedAppID = nil
    }

    /// Called by the section once it has handled `intent`.
    func consume(_ intent: WorkspaceIntent) {
        if self.intent == intent { self.intent = nil }
    }
}
