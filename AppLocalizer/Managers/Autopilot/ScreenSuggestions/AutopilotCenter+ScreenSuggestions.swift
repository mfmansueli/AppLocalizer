//
//  AutopilotCenter+ScreenSuggestions.swift
//  AppLocalizer
//

import Foundation

/// Suggest Screens: the person asks (optionally for something specific),
/// the assistant reads the UI tests, the commits since the last version and
/// the live set and answers with `propose_screens`, and the person adds
/// the ones they want. Nothing is added on its own. It works for the set's
/// screens (iPhone and iPad) and for Apple Watch's own.
extension AutopilotCenter {
    /// Apple's limit: up to 10 screenshots per device.
    nonisolated static let maximumScreens = ScreenshotTemplate.maximumSlots

    /// Suggest Screens: the assistant is asked through `next_step`, for
    /// `display`'s screens (iPhone for the set's).
    func requestScreenSuggestions(appID: StoreApp.ID, ask: String?, on display: ScreenshotDisplayType = .iPhone) {
        update(appID) { run in
            guard run.stage == .plan, run.plan.takesNewScreens(on: display), run.plan.screenRoom(on: display) > 0 else { return }
            let ask = ask?.trimmingCharacters(in: .whitespacesAndNewlines)
            run.screenRequest = AutopilotScreenRequest(
                ask: ask?.isEmpty == false ? ask : nil, askedAt: now(), displayType: display.hasOwnScreens ? display : nil
            )
            run.screenSuggestions = nil
        }
    }

    func cancelScreenSuggestions(appID: StoreApp.ID) {
        update(appID) { $0.screenRequest = nil }
    }

    /// The assistant's suggestions; they replace the ones shown before.
    /// Apple Watch's have no caption: its screenshots are the captures.
    @discardableResult
    func receiveScreenSuggestions(_ items: [AutopilotScreenSuggestion], client: String, appID: StoreApp.ID) throws -> AutopilotScreenSuggestions {
        guard let run = runs[appID], run.stage == .plan, let request = run.screenRequest else {
            throw AutopilotError(String(localized: "Nobody asked for screens now. The person asks with Suggest Screens in the plan."))
        }
        guard !items.isEmpty else {
            throw AutopilotError(String(localized: "Send at least one screen, each with a name, why and the steps."))
        }
        let captioned = request.device.hasCaptions ? items : items.map { item in
            var item = item
            item.caption = ""
            return item
        }
        let suggestions = AutopilotScreenSuggestions(
            ask: request.ask, client: client, items: captioned, receivedAt: now(), displayType: request.displayType
        )
        update(appID) { run in
            run.screenRequest = nil
            run.screenSuggestions = suggestions
        }
        return suggestions
    }

    /// Add to Plan: after the device's screens (the set's, or Apple
    /// Watch's), marked as suggested. A screen sent outside Suggest Screens
    /// comes from the ones kept for the next plan.
    func addSuggestedScreen(_ id: String, appID: StoreApp.ID) {
        guard runs[appID]?.screenSuggestions?.items.contains(where: { $0.id == id }) == true else {
            addQueuedScreen(id, appID: appID)
            return
        }
        update(appID) { run in
            guard let suggestions = run.screenSuggestions,
                  let index = suggestions.items.firstIndex(where: { $0.id == id && $0.status == .open }),
                  Self.append(suggestions.items[index], from: suggestions, to: &run)
            else { return }
            run.screenSuggestions?.items[index].status = .added
        }
    }

    func dismissScreenSuggestion(_ id: String, appID: StoreApp.ID) {
        guard runs[appID]?.screenSuggestions?.items.contains(where: { $0.id == id }) == true else {
            dismissQueuedScreen(id, appID: appID)
            return
        }
        update(appID) { run in
            guard let index = run.screenSuggestions?.items.firstIndex(where: { $0.id == id }) else { return }
            run.screenSuggestions?.items[index].status = .dismissed
        }
    }

    /// Puts a suggested screen at the end of its device's, while the plan
    /// is open and has room; false when it can't.
    static func append(_ item: AutopilotScreenSuggestion, from suggestions: AutopilotScreenSuggestions, to run: inout AutopilotRun) -> Bool {
        let display = suggestions.device
        guard run.stage == .plan, item.status == .open, run.plan.takesNewScreens(on: display), run.plan.screenRoom(on: display) > 0 else {
            return false
        }
        let id = run.plan.newScreenID(named: item.name, on: display)
        run.plan.appendScreen(item.screen(id: id, on: display, client: suggestions.client), on: display)
        run.keptCaptureCount = run.keptTargetCount
        return true
    }

    /// Done: the suggestions go away; the added screens stay.
    func closeScreenSuggestions(appID: StoreApp.ID) {
        update(appID) { $0.screenSuggestions = nil }
    }
}
