//
//  AutopilotCenter+ScreenSuggestions.swift
//  AppLocalizer
//

import Foundation

/// Suggest Screens: the person asks (optionally for something specific),
/// the assistant reads the UI tests, the commits since the last version and
/// the live set and answers with `propose_screens`, and the person adds
/// the ones they want. Nothing is added on its own.
extension AutopilotCenter {
    /// Apple's limit: up to 10 screenshots per device.
    nonisolated static let maximumScreens = ScreenshotTemplate.maximumSlots

    /// Suggest Screens: the assistant is asked through `next_step`.
    func requestScreenSuggestions(appID: StoreApp.ID, ask: String?) {
        update(appID) { run in
            guard run.stage == .plan, run.plan.screens.count < Self.maximumScreens else { return }
            let ask = ask?.trimmingCharacters(in: .whitespacesAndNewlines)
            run.screenRequest = AutopilotScreenRequest(ask: ask?.isEmpty == false ? ask : nil, askedAt: now())
            run.screenSuggestions = nil
        }
    }

    func cancelScreenSuggestions(appID: StoreApp.ID) {
        update(appID) { $0.screenRequest = nil }
    }

    /// The assistant's suggestions; they replace the ones shown before.
    @discardableResult
    func receiveScreenSuggestions(_ items: [AutopilotScreenSuggestion], client: String, appID: StoreApp.ID) throws -> AutopilotScreenSuggestions {
        guard let run = runs[appID], run.stage == .plan, let request = run.screenRequest else {
            throw AutopilotError(String(localized: "Nobody asked for screens now. The person asks with Suggest Screens in the plan."))
        }
        guard !items.isEmpty else {
            throw AutopilotError(String(localized: "Send at least one screen, each with a name, why and the steps."))
        }
        let suggestions = AutopilotScreenSuggestions(ask: request.ask, client: client, items: items, receivedAt: now())
        update(appID) { run in
            run.screenRequest = nil
            run.screenSuggestions = suggestions
        }
        return suggestions
    }

    /// Add to Plan: after the iPhone and iPad screens, marked as suggested.
    func addSuggestedScreen(_ id: String, appID: StoreApp.ID) {
        update(appID) { run in
            guard run.stage == .plan, run.plan.screens.count < Self.maximumScreens,
                  let index = run.screenSuggestions?.items.firstIndex(where: { $0.id == id && $0.status == .open }),
                  let suggestions = run.screenSuggestions
            else { return }
            let item = suggestions.items[index]
            run.plan.appendScreen(
                AutopilotScreen(
                    id: run.plan.newScreenID(named: item.name, on: .iPhone), name: item.name, steps: item.steps, caption: item.caption,
                    origin: .suggestion(client: suggestions.client)
                ),
                on: .iPhone
            )
            run.screenSuggestions?.items[index].status = .added
            run.keptCaptureCount = run.keptTargetCount
        }
    }

    func dismissScreenSuggestion(_ id: String, appID: StoreApp.ID) {
        update(appID) { run in
            guard let index = run.screenSuggestions?.items.firstIndex(where: { $0.id == id }) else { return }
            run.screenSuggestions?.items[index].status = .dismissed
        }
    }

    /// Done: the suggestions go away; the added screens stay.
    func closeScreenSuggestions(appID: StoreApp.ID) {
        update(appID) { $0.screenSuggestions = nil }
    }
}
