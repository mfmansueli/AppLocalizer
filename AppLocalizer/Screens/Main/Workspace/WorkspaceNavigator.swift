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
    /// Activity history (the toolbar clock).
    var isActivityPresented = false
    /// Set by Activity's "Restore Previous Values": Review & Push opens once
    /// Activity has closed (macOS shows one sheet at a time).
    var opensReviewAfterActivity = false
    /// What the current section should do next; nil when nothing is pending.
    private(set) var intent: WorkspaceIntent?
    /// Bumped by Refresh (⌘R). The library and every section reload when it
    /// changes (`.onChange(of: navigator.refreshCount)`).
    private(set) var refreshCount = 0

    init(section: AppWorkspaceSection = .overview) {
        self.section = section
    }

    /// Switches to `section` and leaves `intent` for it to handle.
    func open(_ section: AppWorkspaceSection, intent: WorkspaceIntent? = nil) {
        self.section = section
        self.intent = intent
    }

    /// Asks the current section to do something without switching.
    func send(_ intent: WorkspaceIntent) {
        self.intent = intent
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

    /// Called by the section once it has handled `intent`.
    func consume(_ intent: WorkspaceIntent) {
        if self.intent == intent { self.intent = nil }
    }
}
