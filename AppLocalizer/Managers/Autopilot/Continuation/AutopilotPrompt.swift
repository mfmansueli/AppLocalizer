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
