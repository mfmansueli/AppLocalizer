//
//  StudioDebugPlanProposals.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// What the assistant sent for the plan outside a run, as Alba's 1.1 had
/// it:
/// - `ap-plan-sent`: Here's the plan with a change waiting (Week's new
///   steps, the sample data, the fixes' commands removed), My Phrases
///   suggested for the set, and the simulator options open on a command
///   and a note fixes added.
@MainActor
enum StudioDebugPlanProposals {
    nonisolated static let ids = ["ap-plan-sent"]

    /// The change waiting for Accept or Reject.
    nonisolated static let changeID = "pc-sent"
    /// The screens waiting under the set's, and My Phrases among them.
    nonisolated static let screensID = "ps-sent"
    nonisolated static let screenID = "ps-sent-1"

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        guard id == "ap-plan-sent" else { return nil }
        var run = StudioDebugGuided.planned()
        run.plan.simulator.extraCommands = ["xcrun simctl privacy booted grant photos com.northpier.lumen"]
        run.plan.simulator.fixNotes = ["Install the iOS 27.1+ simulator runtime in Xcode → Settings → Components."]
        let appID = run.appID
        let sent = StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 25)
        return StudioDebugExtras.Scene(run: run, sheet: true, setUp: { model in
            model.studio.guided.setupStep = .plan
            model.studio.guided.showsSimulator = true
            guard let center = model.studio.autopilot else { return }
            center.queuePlanChange(change(at: sent), appID: appID)
            _ = try? center.queueScreenSuggestions([myPhrases], on: .iPhone, client: StudioDebugRuns.client, appID: appID)
            center.updatePlanProposals(appID) { proposals in
                proposals.screens[proposals.screens.count - 1].id = screensID
            }
        })
    }

    private static func change(at date: Date) -> AutopilotPlanChange {
        AutopilotPlanChange(
            id: changeID, client: StudioDebugRuns.client, receivedAt: date,
            reason: "1.4 reaches Week from the new tab bar, and the sample week loads from a launch argument.",
            evidence: "LumenUITests/ScreenshotTests.swift, commit 4f2c9e1",
            screens: [AutopilotScreenStepsChange(screenID: "week", name: "Week", steps: "tab “Week” → wait for the mood chart")],
            sampleData: "launch argument -ui-sample-week",
            setupCommands: []
        )
    }

    private static let myPhrases = AutopilotScreenSuggestion(
        id: screenID, name: "My Phrases", reason: "New in 1.4: the phrases the person keeps.",
        evidence: "MyPhrasesView.swift", steps: "tab “My Phrases” → wait for the list", caption: "Keep the words that move you"
    )
}
#endif
