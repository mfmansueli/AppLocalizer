//
//  AutopilotStripContent.swift
//  AppLocalizer
//

import Foundation

/// The strip above the preview: what Autopilot is doing, and the buttons
/// for it. Without an assistant that can run Xcode it says so; while it
/// runs it shows progress, "Your turn" at a checkpoint and a red pill for a
/// problem.
struct AutopilotStripContent: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case idle
        case needsAssistant
        case running
        case yourTurn
        case ready
    }

    var kind: Kind
    var title: String
    var pill: String?
    var pillStyle: PillStyle = .outline
    var text: String
    /// 0–1 while running.
    var progress: Double?
    var primary: AutopilotStripAction
    var secondary: AutopilotStripAction?
    /// The assistant and design project pills.
    var showsConnections: Bool { kind == .idle }

    /// - Parameters:
    ///   - assistant: The connected assistant that can run Xcode, if any.
    ///   - hasNewSet: Renders wait in Review & Push.
    static func make(
        run: AutopilotRun?,
        appName: String,
        assistant: String?,
        designProject: DesignProject?,
        hasNewSet: Bool
    ) -> AutopilotStripContent {
        let stage = run?.stage
        if let run, let stage, stage.isRunning {
            return running(run, stage: stage)
        }
        if let run, let stage, stage.waitsForPerson {
            return yourTurn(run, stage: stage)
        }
        if let run, stage == .ready, hasNewSet {
            return ready(run)
        }
        guard let assistant else {
            return AutopilotStripContent(
                kind: .needsAssistant,
                title: String(localized: "Screenshot Autopilot"),
                pill: String(localized: "Needs an assistant"),
                text: String(localized: "Capturing runs \(appName) in Simulator through an assistant that can use Xcode, such as Claude Code, Codex or Cursor. Without one, import your captures by hand; design and localizing still work."),
                primary: .setUpAssistant,
                secondary: .importCaptures
            )
        }
        let design = if let designProject {
            String(localized: "\(designProject.kind.title) designs the set in \(designProject.displayName).")
        } else {
            String(localized: "Your design project, if you connect one, designs the set in your brand.")
        }
        return AutopilotStripContent(
            kind: .idle,
            title: String(localized: "Screenshot Autopilot"),
            pill: run == nil ? String(localized: "New") : nil,
            text: String(localized: "\(assistant) runs \(appName) in Simulator and captures every screen in every language.") + " " + design + " "
                + String(localized: "AppLocalizer localizes, checks and keeps every step here."),
            primary: .runAutopilot
        )
    }

    private static func running(_ run: AutopilotRun, stage: AutopilotStage) -> AutopilotStripContent {
        let client = run.client ?? String(localized: "the assistant")
        let total = run.totalCaptures
        let (text, progress): (String, Double) = switch stage {
        case .waiting:
            (String(localized: "Waiting for \(client) to pick up the plan"), 0.02)
        case .capture:
            (captureText(run), total > 0 ? Double(run.capturedCount) / Double(total) : 0)
        case .design:
            (
                String(localized: "\(designer(run)) is designing · \(run.directions.count) of \(AutopilotRun.directionCount) directions"),
                Double(run.directions.count) / Double(AutopilotRun.directionCount)
            )
        default:
            (
                String(localized: "Localizing and checking · \(run.checkedScreenshots) of \(run.totalScreenshots)"),
                run.totalScreenshots > 0 ? Double(run.checkedScreenshots) / Double(run.totalScreenshots) : 0
            )
        }
        let problems = run.problemGroups.count
        return AutopilotStripContent(
            kind: .running,
            title: String(localized: "Autopilot is running"),
            pill: problems == 0 ? nil : problems == 1 ? String(localized: "1 problem") : String(localized: "\(problems) problems"),
            pillStyle: .danger,
            text: text,
            progress: min(max(progress, 0.02), 1),
            primary: .open
        )
    }

    /// "Capturing · German · iPhone 6.9″ · Today · 31 of 120".
    private static func captureText(_ run: AutopilotRun) -> String {
        var parts = [String(localized: "Capturing")]
        if let latest = run.latestCapture {
            parts.append(StoreLocaleCatalog.locale(code: latest.target.locale)?.shortName ?? latest.target.locale)
            parts.append(latest.target.displayType.title)
            parts.append(run.plan.screen(id: latest.target.screenID)?.name ?? latest.target.screenID)
        }
        parts.append(String(localized: "\(run.capturedCount) of \(run.totalCaptures)"))
        return parts.joined(separator: " · ")
    }

    private static func yourTurn(_ run: AutopilotRun, stage: AutopilotStage) -> AutopilotStripContent {
        let client = run.client ?? String(localized: "The assistant")
        let screens = run.plan.screens.count
        let text = stage == .pick
            ? String(localized: "Pick the best captures for \(screens) screens. \(client)’s picks are already selected.")
            : String(localized: "Choose one of \(run.directions.count) directions from \(designer(run)).")
        return AutopilotStripContent(
            kind: .yourTurn,
            title: String(localized: "Autopilot is waiting for you"),
            pill: String(localized: "Your turn"),
            pillStyle: .machineTranslated,
            text: text,
            primary: .open
        )
    }

    private static func ready(_ run: AutopilotRun) -> AutopilotStripContent {
        var parts = [String(localized: "\(run.totalScreenshots) screenshots")]
        if let direction = run.chosenDirection { parts[0] += " " + String(localized: "in \(direction.name)") }
        let shortened = run.shortenings.count
        if shortened == 1 { parts.append(String(localized: "1 caption shortened")) }
        if shortened > 1 { parts.append(String(localized: "\(shortened) captions shortened")) }
        parts.append(String(localized: "waiting in Review & Push"))
        return AutopilotStripContent(
            kind: .ready,
            title: String(localized: "New set ready"),
            pill: String(localized: "Not pushed"),
            pillStyle: .accent,
            text: parts.joined(separator: " · "),
            primary: .reviewPush,
            secondary: .open
        )
    }

    /// "Claude Design" or "AppLocalizer’s starters".
    static func designer(_ run: AutopilotRun) -> String {
        run.designKind.usesDesignAI ? run.designKind.title : String(localized: "AppLocalizer’s starters")
    }
}
