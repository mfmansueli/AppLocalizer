//
//  StudioDebugAddScreens.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Board 28's scenes, "Add or suggest screens":
/// - `st-plan-add`: "+ Add a Screen…"'s form, Insights, steps left to
///   Claude Code.
/// - `st-plan-suggest-busy`: Suggest Screens while Claude Code reads.
/// - `st-plan-suggest`: Claude Code's three suggestions.
/// - `st-plan-suggest-ask`: asked for "one that shows the streak".
/// - `st-plan-added`: two new screens in the plan, one suggested, one
///   added by hand.
/// - `st-plan-watch-add`: Lumen on every device, "+ Add a Screen…" open
///   under Apple Watch's screens (no caption).
/// - `st-plan-watch-busy`: Suggest Screens for Apple Watch while Claude
///   Code reads the watch app.
/// - `st-plan-watch-suggest`: Claude Code's three watch screens.
@MainActor
enum StudioDebugAddScreens {
    nonisolated static let ids = [
        "st-plan-add", "st-plan-suggest-busy", "st-plan-suggest", "st-plan-suggest-ask", "st-plan-added",
        "st-plan-watch-add", "st-plan-watch-busy", "st-plan-watch-suggest",
    ]

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        let asked = StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 20)
        switch id {
        case "st-plan-add":
            return StudioDebugExtras.Scene(run: StudioDebugRuns.run(.plan), sheet: true) { model in
                model.studio.screenDraft = AutopilotScreenDraft(name: "Insights", caption: "See what lifts your mood")
            }
        case "st-plan-suggest-busy":
            var run = StudioDebugRuns.run(.plan)
            run.screenRequest = AutopilotScreenRequest(ask: nil, askedAt: asked)
            return StudioDebugExtras.Scene(run: run, sheet: true)
        case "st-plan-suggest":
            return StudioDebugExtras.Scene(run: suggested(ask: nil), sheet: true)
        case "st-plan-suggest-ask":
            return StudioDebugExtras.Scene(run: suggested(ask: "one that shows the streak"), sheet: true) { model in
                model.studio.screenAsk = "one that shows the streak"
            }
        case "st-plan-added":
            var run = suggested(ask: nil)
            run.screenSuggestions?.items[0].status = .added
            run.screenSuggestions?.items[2].status = .dismissed
            run.plan.appendScreen(
                AutopilotScreen(
                    id: "insights", name: "Insights", steps: suggestions[0].steps, caption: suggestions[0].caption,
                    origin: .suggestion(client: StudioDebugRuns.client)
                ),
                on: .iPhone
            )
            run.plan.appendScreen(AutopilotScreen(id: "settings", name: "Reminders", origin: .person, worksOutSteps: true), on: .iPhone)
            return StudioDebugExtras.Scene(run: run, sheet: true)
        default:
            return watchScene(for: id, asked: asked)
        }
    }

    /// Apple Watch's add and suggest, with Lumen on every device.
    private static func watchScene(for id: String, asked: Date) -> StudioDebugExtras.Scene? {
        var run = StudioDebugRuns.run(.plan, everyDevice: true)
        switch id {
        case "st-plan-watch-add":
            return StudioDebugExtras.Scene(run: run, sheet: true, setUp: { model in
                model.studio.screenDraft = AutopilotScreenDraft(name: "Mood history", displayType: .watch)
            }, everyDevice: true)
        case "st-plan-watch-busy":
            run.screenRequest = AutopilotScreenRequest(ask: nil, askedAt: asked, displayType: .watch)
            return StudioDebugExtras.Scene(run: run, sheet: true, everyDevice: true)
        case "st-plan-watch-suggest":
            run.screenSuggestions = AutopilotScreenSuggestions(
                ask: nil, client: StudioDebugRuns.client, items: watchSuggestions,
                receivedAt: StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 21), displayType: .watch
            )
            return StudioDebugExtras.Scene(run: run, sheet: true, everyDevice: true)
        default:
            return nil
        }
    }

    /// Claude Code's three for LumenWatch: dictation (new in 1.4), the
    /// Smart Stack widget, the month of moods. No captions on the watch.
    static let watchSuggestions = [
        AutopilotScreenSuggestion(
            id: "sg-watch-speak", name: "Speak an entry",
            reason: "New in 1.4 and in no watch screenshot yet: an entry dictated from the wrist.",
            evidence: "LumenWatch/SpeakEntryView.swift", steps: "LumenWatch → Today → tap “Speak an Entry” → sample transcript", caption: ""
        ),
        AutopilotScreenSuggestion(
            id: "sg-watch-stack", name: "Smart Stack widget",
            reason: "The streak in the Smart Stack shows Lumen on the wrist without opening the app.",
            evidence: "LumenWatchWidgets target", steps: "watch face → turn the crown to the Smart Stack → Lumen streak widget", caption: ""
        ),
        AutopilotScreenSuggestion(
            id: "sg-watch-month", name: "Mood history",
            reason: "A month of moods as a ring is what people check at a glance.",
            evidence: nil, steps: "LumenWatch → swipe to Week → tap “Month”", caption: ""
        ),
    ]

    /// Claude Code's three: what's new in 1.4, the widget, Dark Mode.
    static let suggestions = [
        AutopilotScreenSuggestion(
            id: "sg-insights", name: "Insights",
            reason: "New in 1.4 and in no screenshot yet: the main feature of the 23 commits since v1.3.",
            evidence: "Lumen/Insights/InsightsView.swift", steps: "tab “Insights” → wait for the mood chart", caption: "See what lifts your mood"
        ),
        AutopilotScreenSuggestion(
            id: "sg-widget", name: "Streak widget",
            reason: "Lumen ships a widget. A Home Screen with it shows Lumen works outside the app too.",
            evidence: "LumenWidget target", steps: "add LumenWidget (medium) to the Home Screen → sample 12-day streak",
            caption: "Your streak, on your Home Screen"
        ),
        AutopilotScreenSuggestion(
            id: "sg-dark", name: "Today in Dark Mode",
            reason: "Lumen supports Dark Mode and no screenshot shows it. One dark screen says it’s easy on the eyes at night.",
            evidence: nil, steps: "launch -ui-sample-week -AppleInterfaceStyle Dark → Today", caption: "Easy on the eyes at night"
        ),
    ]

    /// The plan with the suggestions shown; asked for the streak, the
    /// widget comes first.
    static func suggested(ask: String?) -> AutopilotRun {
        var run = StudioDebugRuns.run(.plan)
        let items = ask == nil ? suggestions : [suggestions[1], suggestions[0], suggestions[2]]
        run.screenSuggestions = AutopilotScreenSuggestions(
            ask: ask, client: StudioDebugRuns.client, items: items, receivedAt: StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 21)
        )
        return run
    }
}
#endif
