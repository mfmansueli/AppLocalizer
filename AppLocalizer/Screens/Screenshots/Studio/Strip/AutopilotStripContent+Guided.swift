//
//  AutopilotStripContent+Guided.swift
//  AppLocalizer
//

import Foundation

/// The strip for the guided Autopilot: Start… (or Continue Setup…) with
/// what it makes in three steps, the run's progress while it goes on its
/// own, "Your turn" at the two stops, and Sent once it's pushed.
extension AutopilotStripContent {
    /// - Parameters:
    ///   - assistant: The connected assistant that can run Xcode, if any.
    ///   - hasNewSet: Renders wait in Review & Push.
    ///   - stall: Why nobody works on the run although it has work left.
    static func guided(
        run: AutopilotRun?,
        appName: String,
        assistant: String?,
        designProject: DesignProject?,
        hasNewSet: Bool,
        stall: AutopilotStall? = nil,
        now: Date = .now
    ) -> AutopilotStripContent {
        let stage = run?.stage
        if assistant == nil, stage == nil || stage == .plan || (stage == .ready && run?.guidedReview?.pushedAt != nil) {
            return make(run: run, appName: appName, assistant: assistant, designProject: designProject, hasNewSet: hasNewSet)
        }
        guard let run, let stage else { return start(isSetUp: false) }
        switch stage {
        case .plan:
            return start(isSetUp: true)
        case .waiting, .capture, .design, .localize:
            return running(run, stall: stall, now: now)
        case .pick:
            return yourTurn(
                text: String(localized: "Pick the captures: every screen has its tries ready."),
                title: String(localized: "Pick the Captures…")
            )
        case .choose:
            return yourTurn(
                text: chooseText(run),
                title: String(localized: "Choose the Look…")
            )
        case .watchPreview:
            return yourTurn(text: reviewText, title: String(localized: "Review…"))
        case .ready:
            guard run.guidedReview?.pushedAt != nil else {
                return yourTurn(text: reviewText, title: String(localized: "Review…"))
            }
            return AutopilotStripContent(
                kind: .ready,
                title: String(localized: "Sent to the App Store"),
                pill: String(localized: "Pushed"),
                pillStyle: .decrease,
                text: String(localized: "Apple is processing the new files; the live page changes within minutes."),
                primary: .runAutopilot,
                primaryTitle: String(localized: "New Run…"),
                secondary: .open
            )
        }
    }

    private static let reviewText = String(localized: "Everything is made and checked. Review it, then push.")

    /// "Choose the look: the screenshot looks and headers are ready."
    private static func chooseText(_ run: AutopilotRun) -> String {
        switch (run.choosesDirection, run.usesConcepts) {
        case (true, true):
            String(localized: "Choose the look: the screenshot looks and headers are ready.")
        case (false, true):
            String(localized: "Choose the look: the headers are ready.")
        case _ where run.plan.makesScreenshots:
            String(localized: "Choose the look: the screenshot looks are ready.")
        default:
            String(localized: "Choose the look: the App Preview’s looks are ready.")
        }
    }

    private static func start(isSetUp: Bool) -> AutopilotStripContent {
        AutopilotStripContent(
            kind: .idle,
            title: String(localized: "Autopilot"),
            pill: isSetUp ? nil : String(localized: "New"),
            pillStyle: .accent,
            text: String(localized: """
            Make new screenshots, an App Preview and header artwork in 3 short steps. Autopilot does the rest and asks \
            you only to choose the look and to review.
            """),
            primary: isSetUp ? .open : .runAutopilot,
            primaryTitle: isSetUp ? String(localized: "Continue Setup…") : String(localized: "Start…")
        )
    }

    /// "Designing in Northpier Brand · 40%. You’ll be notified when it
    /// needs you."
    /// Paused (AppLocalizer was closed) or stopped, it says so instead:
    /// MB Admin's strip said "Autopilot is running" while nothing ran.
    private static func running(_ run: AutopilotRun, stall: AutopilotStall?, now: Date) -> AutopilotStripContent {
        let progress = GuidedRunProgress.make(run, now: now)
        let percent = Int((progress.fraction * 100).rounded())
        let problems = run.problemGroups.count
        var content = AutopilotStripContent(
            kind: .running,
            title: String(localized: "Autopilot is running"),
            pill: problems == 0 ? nil : problems == 1 ? String(localized: "1 problem") : String(localized: "\(problems) problems"),
            pillStyle: .danger,
            text: String(localized: "\(progress.title) · \(percent)%. You’ll be notified when it needs you."),
            progress: min(max(progress.fraction, 0.02), 1),
            primary: .open
        )
        switch stall {
        case .notRunning:
            content.title = String(localized: "Autopilot is paused")
        case .ended:
            content.title = String(localized: "Autopilot stopped")
        case .quiet, .handedBack, nil:
            return content
        }
        content.text = stall?.headline(of: run, now: now) ?? content.text
        content.primaryTitle = String(localized: "Continue…")
        return content
    }

    private static func yourTurn(text: String, title: String) -> AutopilotStripContent {
        AutopilotStripContent(
            kind: .yourTurn,
            title: String(localized: "Autopilot needs you"),
            pill: String(localized: "Your turn"),
            pillStyle: .machineTranslated,
            text: text,
            primary: .open,
            primaryTitle: title
        )
    }
}
