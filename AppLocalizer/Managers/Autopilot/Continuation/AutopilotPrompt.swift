//
//  AutopilotPrompt.swift
//  AppLocalizer
//

import Foundation

/// What Claude Code is asked to do for a run: start it, or continue one it
/// stopped. Pasted, or passed when AppLocalizer starts Claude Code.
enum AutopilotPrompt {
    /// Start Autopilot's prompt.
    static func start(appName: String, appID: StoreApp.ID, plan: AutopilotPlan) -> String {
        guard plan.makesScreenshots else { return withoutScreenshots(appName: appName, appID: appID, plan: plan) }
        let count = plan.localeCodes.count
        let languages = if count == 1 {
            String(localized: "1 language")
        } else if plan.includesNewLanguages {
            String(localized: "all \(count) languages the app supports")
        } else {
            String(localized: "all \(count) languages")
        }
        let screens = plan.displayTypes.contains(where: \.hasOwnScreens)
            ? String(localized: "every screen")
            : String(localized: "the \(plan.screens.count) screens")
        // The assistant picks the screens unless the person keeps theirs.
        let work = plan.choosesScreens
            ? String(localized: "decide which screens show \(appName) best, build the app, capture them")
            : String(localized: "build the app, capture \(screens)")
        return String(localized: "Run \(appName)’s screenshot plan from AppLocalizer: \(work) on \(plan.devicesTitle) in \(languages), and send the captures back.")
            + " " + String(localized: "Start with get_capture_plan for app \(appID), then ask next_step after each step.")
            + " " + keepGoing
    }

    /// A run without screenshots: the header and search artwork, the App
    /// Preview, or both.
    static func withoutScreenshots(appName: String, appID: StoreApp.ID, plan: AutopilotPlan) -> String {
        var work: [String] = []
        if !plan.targets.isEmpty { work.append(String(localized: "build the app, capture the screens the header and search artwork show")) }
        if !plan.recordingTargets.isEmpty { work.append(String(localized: "record the App Preview walkthrough")) }
        let what = plan.extrasTitle ?? String(localized: "its extras")
        let list = work.formatted(.list(type: .and))
        let steps = list.prefix(1).uppercased() + list.dropFirst()
        let lead = work.isEmpty
            ? String(localized: "Run \(appName)’s Autopilot run from AppLocalizer: it makes \(what) from the last captures, and no screenshots.")
            : String(localized: "Run \(appName)’s Autopilot run from AppLocalizer: it makes \(what), and no screenshots. \(steps), and send them back.")
        return lead + " " + String(localized: "Start with get_capture_plan for app \(appID), then ask next_step after each step.") + " " + keepGoing
    }

    /// Suggest Screens: the assistant suggests screens for the plan (the
    /// set's, or Apple Watch's own); the person adds the ones they want.
    static func suggestScreens(appName: String, appID: StoreApp.ID, ask: String, on display: ScreenshotDisplayType = .iPhone) -> String {
        let ask = ask.trimmingCharacters(in: .whitespacesAndNewlines)
        let what = ask.isEmpty ? "" : " " + String(localized: "The person asks for: “\(ask)”.")
        let lead = display == .watch
            ? String(localized: "Suggest new Apple Watch screens for \(appName)’s screenshot plan in AppLocalizer.")
            : String(localized: "Suggest new screens for \(appName)’s screenshot plan in AppLocalizer.")
        return lead + what + " "
            + String(localized: "Call next_step for app \(appID) and do what it says; the person adds the ones they want.")
    }

    /// What picks `run` up where it is.
    static func continuing(_ run: AutopilotRun, appName: String) -> String {
        continuing(appName: appName, appID: run.appID)
    }

    /// The prompt that picks a stopped run up where it is.
    static func continuing(appName: String, appID: StoreApp.ID) -> String {
        String(localized: """
        Continue \(appName)’s screenshot run from AppLocalizer where it stopped: call get_capture_plan for app \(appID) \
        for the plan, commands and upload link, then ask next_step and do what it says after each step.
        """) + " " + keepGoing
    }

    /// Don't stop for one screen or device.
    private static var keepGoing: String {
        String(localized: """
        Keep going until next_step says done or wait: report a screen you can’t capture with report_capture_problem \
        (affectsDevice: true when this Mac can’t run the device) and go on with the rest.
        """)
    }
}
