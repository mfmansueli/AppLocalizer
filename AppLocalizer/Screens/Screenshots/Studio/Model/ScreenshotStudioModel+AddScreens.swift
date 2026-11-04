//
//  ScreenshotStudioModel+AddScreens.swift
//  AppLocalizer
//

import AppKit
import Foundation

/// The plan's two ways to add a screen: "+ Add a Screen…" by hand, and
/// Suggest Screens, which asks the assistant and shows what it suggests.
/// Both work for the set's screens (iPhone and iPad, `.iPhone` here) and for
/// Apple Watch's own.
extension ScreenshotStudioModel {
    /// Apple's 10 screenshots per device are planned for the set.
    var plansMaximumScreens: Bool { plansMaximumScreens(on: .iPhone) }

    /// Apple's 10 screenshots are planned on `display`.
    func plansMaximumScreens(on display: ScreenshotDisplayType) -> Bool {
        (run?.plan.screenRoom(on: display) ?? AutopilotCenter.maximumScreens) <= 0
    }

    /// What the person asks the set's Suggest Screens for.
    var screenAsk: String {
        get { screenAsk(on: .iPhone) }
        set { setScreenAsk(newValue, on: .iPhone) }
    }

    func screenAsk(on display: ScreenshotDisplayType) -> String {
        screenAsks[display] ?? ""
    }

    func setScreenAsk(_ ask: String, on display: ScreenshotDisplayType) {
        screenAsks[display] = ask
    }

    // MARK: - Add a Screen

    func openScreenForm(on display: ScreenshotDisplayType = .iPhone) {
        showsPlanScreens = true
        screenDraft = AutopilotScreenDraft(displayType: display)
        autopilot?.closeScreenSuggestions(appID: app.id)
    }

    func addDraftScreen() {
        guard let draft = screenDraft, draft.canAdd, !plansMaximumScreens(on: draft.displayType) else { return }
        updatePlan { plan in
            plan.appendScreen(draft.screen(id: plan.newScreenID(named: draft.name, on: draft.displayType)), on: draft.displayType)
        }
        screenDraft = nil
    }

    // MARK: - Suggest Screens

    /// Asks the assistant for `display`'s screens; AppLocalizer starts
    /// Claude Code for it, or copies the prompt to paste.
    func suggestScreens(on display: ScreenshotDisplayType = .iPhone) {
        guard let autopilot, !plansMaximumScreens(on: display) else { return }
        showsPlanScreens = true
        screenDraft = nil
        didCopySuggestPrompt = false
        let ask = screenAsk(on: display)
        autopilot.requestScreenSuggestions(appID: app.id, ask: ask, on: display)
        let prompt = AutopilotPrompt.suggestScreens(appName: app.name, appID: app.id, ask: ask, on: display)
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
    /// screenshots…"; for Apple Watch, the watch app's.
    func suggestBusyText(client: String, on display: ScreenshotDisplayType = .iPhone) -> String {
        let version = screenshots.context.version.versionString
        if display == .watch {
            return String(localized: "\(client) is reading the watch app, its UI tests, the \(version) commits and the live watch screenshots…")
        }
        return String(localized: "\(client) is reading \(uiTestsName), the \(version) commits and the live screenshots…")
    }

    /// "Screens Lumen’s set is missing", "Apple Watch screens Lumen is
    /// missing", "For “one that shows the streak”".
    func suggestionsTitle(_ suggestions: AutopilotScreenSuggestions) -> String {
        if let ask = suggestions.ask { return String(localized: "For “\(ask)”") }
        return suggestions.device == .watch
            ? String(localized: "Apple Watch screens \(app.name) is missing")
            : String(localized: "Screens \(app.name)’s set is missing")
    }

    /// Under the set's buttons: where new screens go, or Apple's limit.
    var addScreensNote: String { addScreensNote(on: .iPhone) }

    /// Under `display`'s buttons: where new screens go, or Apple's limit.
    func addScreensNote(on display: ScreenshotDisplayType) -> String {
        guard !plansMaximumScreens(on: display) else {
            return String(localized: "Apple allows up to 10 screenshots per device. Remove a screen to add another.")
        }
        let count = run?.plan.screens(on: display).count ?? 0
        if display == .watch {
            return String(localized: "New screens go after screen \(count) on Apple Watch. Watch screenshots have no captions, so there’s nothing to translate.")
        }
        return String(localized: "New screens go after screen \(count) on iPhone and iPad. Their captions are translated into the run’s languages in Localize and check, where you review them.")
    }

    /// "UI tests" folder or file the assistant adds worked-out steps to:
    /// "LumenUITests".
    var uiTestsName: String {
        run?.plan.writtenFrom.map { ($0 as NSString).pathComponents.first ?? $0 } ?? String(localized: "the UI tests")
    }

    /// Where the assistant adds the steps it works out for `display`'s new
    /// screen: the set's UI tests, or the watch app's.
    func uiTestsName(on display: ScreenshotDisplayType) -> String {
        display == .watch ? String(localized: "the watch app’s UI tests") : uiTestsName
    }
}
