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
    /// The primary button's own title ("Start…", "Choose the Look…"), when
    /// it isn't the action's.
    var primaryTitle: String?
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
            designText(run)
        default:
            localizingText(run)
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

    /// "Claude Design is designing · 1 of 3 directions · 2 of 3 headers".
    private static func designText(_ run: AutopilotRun) -> (String, Double) {
        var parts = [String(localized: "\(designer(run)) is designing")]
        let directions = run.expectedDirections
        if directions > 0 { parts.append(String(localized: "\(min(run.directions.count, directions)) of \(directions) directions")) }
        let concepts = run.expectedConcepts
        if concepts > 0 { parts.append(String(localized: "\(min(run.designedConcepts.count, concepts)) of \(concepts) headers")) }
        let done = min(run.directions.count, directions) + min(run.designedConcepts.count, concepts)
        return (parts.joined(separator: " · "), Double(done) / Double(max(directions + concepts, 1)))
    }

    /// "Localizing and checking · 31 of 40", or for the header and search
    /// only, "Header and search · 4 of 8 languages".
    private static func localizingText(_ run: AutopilotRun) -> (String, Double) {
        if !run.plan.makesScreenshots {
            let extras = run.extrasProgress
            let artwork = !run.plan.artworkKinds.isEmpty
            let done = artwork ? extras?.artworkDone ?? 0 : extras?.previewsDone ?? 0
            let total = artwork ? run.plan.localeCodes.count : run.plan.previewDisplays.count * run.plan.previewLocales.count
            let what = artwork ? String(localized: "Header and search") : String(localized: "App Preview")
            return (String(localized: "\(what) · \(done) of \(total)"), Double(done) / Double(max(total, 1)))
        }
        return (
            String(localized: "Localizing and checking · \(run.checkedScreenshots) of \(run.totalScreenshots)"),
            run.totalScreenshots > 0 ? Double(run.checkedScreenshots) / Double(run.totalScreenshots) : 0
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
        let text = switch stage {
        case .pick: String(localized: "Pick the best captures for \(screens) screens. \(client)’s picks are already selected.")
        case .watchPreview where run.watchesAppPreview && run.watchesHeaderLoop(design: run.designKind):
            String(localized: "Watch the App Preview and the header loop, then approve them or ask for changes.")
        case .watchPreview where run.watchesHeaderLoop(design: run.designKind):
            String(localized: "Watch the header loop, then approve it or ask \(designer(run)) for changes.")
        case .watchPreview where run.reviser != nil:
            String(localized: "Watch the App Preview, then approve it or ask \(designer(run)) for changes.")
        case .watchPreview: String(localized: "Watch the App Preview, then approve it.")
        case .choose where run.usesConcepts: String(localized: "Choose \(run.choicesTitle) from \(designer(run)).")
        default: String(localized: "Choose one of \(run.directions.count) directions from \(designer(run)).")
        }
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
        if !run.plan.makesScreenshots {
            let what = run.plan.extrasTitle ?? String(localized: "the extras")
            return AutopilotStripContent(
                kind: .ready,
                title: String(localized: "Ready for review"),
                pill: String(localized: "Not pushed"),
                pillStyle: .accent,
                text: String(localized: "\(what.prefix(1).uppercased() + what.dropFirst()) in \(run.plan.localeCodes.count) languages · waiting in Review & Push"),
                primary: .reviewPush,
                secondary: .open
            )
        }
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
        if run.designKind.usesDesignAI { return run.designKind.title }
        // Without a design project, Claude designs the header concepts and
        // takes the asks at Watch; the screenshot looks are the starters.
        if let reviser = run.reviser, run.stage == .watchPreview || run.stage == .choose && run.usesConcepts { return reviser.title }
        return String(localized: "AppLocalizer’s starters")
    }
}
