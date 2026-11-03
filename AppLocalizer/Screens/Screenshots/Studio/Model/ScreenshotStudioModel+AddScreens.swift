//
//  ScreenshotStudioModel+AddScreens.swift
//  AppLocalizer
//

import AppKit
import Foundation

/// The plan's two ways to add a screen: "+ Add a Screen…" by hand, and
/// Suggest Screens, which asks the assistant and shows what it suggests.
extension ScreenshotStudioModel {
    /// Apple's 10 screenshots per device are planned.
    var plansMaximumScreens: Bool {
        (run?.plan.screens.count ?? 0) >= AutopilotCenter.maximumScreens
    }

    // MARK: - Add a Screen

    func openScreenForm() {
        showsPlanScreens = true
        screenDraft = AutopilotScreenDraft()
        autopilot?.closeScreenSuggestions(appID: app.id)
    }

    func addDraftScreen() {
        guard let draft = screenDraft, draft.canAdd, !plansMaximumScreens else { return }
        updatePlan { plan in
            plan.appendScreen(draft.screen(id: plan.newScreenID(named: draft.name, on: .iPhone)), on: .iPhone)
        }
        screenDraft = nil
    }

    // MARK: - Suggest Screens

    /// Asks the assistant; AppLocalizer starts Claude Code for it, or copies
    /// the prompt to paste.
    func suggestScreens() {
        guard let autopilot, !plansMaximumScreens else { return }
        showsPlanScreens = true
        screenDraft = nil
        didCopySuggestPrompt = false
        autopilot.requestScreenSuggestions(appID: app.id, ask: screenAsk)
        let prompt = AutopilotPrompt.suggestScreens(appName: app.name, appID: app.id, ask: screenAsk)
        guard let launcher, launcher.canStart else {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(prompt, forType: .string)
            didCopySuggestPrompt = true
            return
        }
        Task { _ = await launcher.start(.autopilot, appID: app.id, appName: app.name, prompt: prompt) }
    }

    func cancelSuggestions() {
        autopilot?.cancelScreenSuggestions(appID: app.id)
        didCopySuggestPrompt = false
    }

    func addSuggestedScreen(_ id: String) {
        autopilot?.addSuggestedScreen(id, appID: app.id)
    }

    func dismissSuggestedScreen(_ id: String) {
        autopilot?.dismissScreenSuggestion(id, appID: app.id)
    }

    func closeSuggestions() {
        autopilot?.closeScreenSuggestions(appID: app.id)
    }

    // MARK: - Texts

    /// "Claude Code is reading LumenUITests, the 1.4 commits and the live
    /// screenshots…".
    func suggestBusyText(client: String) -> String {
        let tests = run?.plan.writtenFrom.map { ($0 as NSString).pathComponents.first ?? $0 } ?? String(localized: "the UI tests")
        let version = screenshots.context.version.versionString
        return String(localized: "\(client) is reading \(tests), the \(version) commits and the live screenshots…")
    }

    /// "Screens Lumen’s set is missing", "For “one that shows the streak”".
    func suggestionsTitle(_ suggestions: AutopilotScreenSuggestions) -> String {
        suggestions.ask.map { String(localized: "For “\($0)”") } ?? String(localized: "Screens \(app.name)’s set is missing")
    }

    /// Under the buttons: where new screens go, or Apple's limit.
    var addScreensNote: String {
        guard !plansMaximumScreens else {
            return String(localized: "Apple allows up to 10 screenshots per device. Remove a screen to add another.")
        }
        let count = run?.plan.screens.count ?? 0
        return String(localized: "New screens go after screen \(count) on iPhone and iPad. Their captions are translated into the run’s languages in Localize and check, where you review them.")
    }

    /// "UI tests" folder or file the assistant adds worked-out steps to:
    /// "LumenUITests".
    var uiTestsName: String {
        run?.plan.writtenFrom.map { ($0 as NSString).pathComponents.first ?? $0 } ?? String(localized: "the UI tests")
    }
}
