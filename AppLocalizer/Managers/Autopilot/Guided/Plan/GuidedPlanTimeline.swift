//
//  GuidedPlanTimeline.swift
//  AppLocalizer
//

import Foundation

/// The guided plan, as a timeline: the assistant captures, the design
/// source designs, the person chooses, AppLocalizer localizes and checks,
/// and the person reviews and pushes, with the stops numbered.
enum GuidedPlanTimeline {
    /// - Parameters:
    ///   - client: "Claude Code".
    ///   - design: The design source Start will use.
    ///   - brand: "Northpier Brand"; nil for the starters.
    ///   - kept: The captures the run reuses.
    ///   - gaps: iPad, iPhone Duo and Mac captured in only some languages
    ///     so far, which the run fills.
    ///   - app: "Lumen", for the gap.
    static func rows(
        plan: AutopilotPlan, client: String, design: DesignProjectKind, brand: String?, kept: Int = 0,
        gaps: [AutopilotInterfaceGap] = [], app: String? = nil
    ) -> [GuidedTimelineRow] {
        var rows: [GuidedTimelineRow] = []
        if let capture = captureRow(plan: plan, client: client, kept: kept, gaps: gaps, app: app) { rows.append(capture) }
        if plan.stopsToPick, plan.makesScreenshots || !plan.artworkTargets.isEmpty {
            rows.append(GuidedTimelineRow(
                kind: .pick, who: .you, title: String(localized: "Pick the captures"),
                detail: String(localized: "\(client) tries each screen up to 3 times; you pick the best before the design starts."), time: ""
            ))
        }
        rows.append(designRow(plan: plan, design: design, brand: brand))
        if plan.stopsToChoose, hasLookToChoose(plan) {
            rows.append(GuidedTimelineRow(
                kind: .choose, who: .you, title: String(localized: "Choose the look"),
                detail: String(localized: "Side by side, with \(GuidedPick.title(design: design))’s pick marked. Ask for changes if none is right."),
                time: ""
            ))
        }
        rows.append(localizeRow(plan: plan, client: client))
        rows.append(GuidedTimelineRow(
            kind: .review, who: .you, title: String(localized: "Review everything and push"),
            detail: String(localized: "Approve each part or ask for changes. Nothing reaches the App Store before you push."), time: ""
        ))
        return numberingStops(rows)
    }

    /// The person's stops: "stop 1 of 2", or "the only stop".
    private static func numberingStops(_ rows: [GuidedTimelineRow]) -> [GuidedTimelineRow] {
        let total = rows.count(where: \.isYours)
        var number = 0
        return rows.map { row in
            guard row.isYours else { return row }
            number += 1
            var row = row
            row.time = total == 1 ? String(localized: "the only stop") : String(localized: "stop \(number) of \(total)")
            return row
        }
    }

    /// Something to choose between: new screenshot looks, App Preview
    /// looks, or header concepts.
    static func hasLookToChoose(_ plan: AutopilotPlan) -> Bool {
        if plan.makesScreenshots { return plan.screenshotStyle != .keep || plan.alsoMakes.makesArtwork }
        return !plan.artworkKinds.isEmpty || !plan.previewDisplays.isEmpty
    }

    /// How many stops the plan makes: the review, and Choose and Pick when
    /// they're on.
    static func stopCount(_ plan: AutopilotPlan) -> Int {
        1 + (plan.stopsToChoose && hasLookToChoose(plan) ? 1 : 0)
            + (plan.stopsToPick && (plan.makesScreenshots || !plan.artworkTargets.isEmpty) ? 1 : 0)
    }

    // MARK: - Rows

    private static func captureRow(
        plan: AutopilotPlan, client: String, kept: Int, gaps: [AutopilotInterfaceGap], app: String?
    ) -> GuidedTimelineRow? {
        let captures = plan.makesScreenshots ? AutopilotEstimate.expectedCaptures(for: plan) : plan.artworkTargets.count
        let records = !plan.previewDisplays.isEmpty
        guard captures > 0 || records else { return nil }
        let screens = plan.makesScreenshots ? plan.screens.count : plan.artworkScreens.count
        let toCapture = max(0, captures - kept)
        // Reusing only part of them (a device the last run didn't make):
        // says both, so the reuse the person turned on is still there.
        let reusesSome = kept > 0 && toCapture > 0 && !plan.awaitsScreens
        let title = captureTitle(plan: plan, screens: screens, kept: reusesSome ? kept : 0, toCapture: toCapture, records: records)
        let devices = plan.runDisplays.map(\.title).formatted(.list(type: .and))
        var detail = if reusesSome {
            String(localized: """
            The captures and picks of the last run, and new ones on \(devices). Problems like a keyboard in the way are fixed and \
            captured again; you’ll see what was fixed.
            """)
        } else if toCapture > 0 || records {
            String(localized: "On \(devices). Problems like a keyboard in the way are fixed and captured again; you’ll see what was fixed.")
        } else {
            String(localized: "The captures and picks of the last run; nothing new to capture.")
        }
        if toCapture > 0, let gap = gapSentence(gaps.filter { plan.displayTypes.contains($0.displayType) }, plan: plan, app: app) {
            detail += " " + gap
        }
        let minutes = (plan.makesScreenshots ? AutopilotEstimate.captureMinutes(for: plan, kept: kept)
            : toCapture > 0 ? AutopilotEstimate.captureMinutes(for: toCapture) : 0) + AutopilotEstimate.recordingMinutes(for: plan)
        return GuidedTimelineRow(
            kind: .capture, who: .assistant(client), title: title, detail: detail,
            time: minutes > 0 ? String(localized: "about \(minutes) min") : String(localized: "a moment")
        )
    }

    /// "Captures 5 screens in Simulator", "Reuses 90 captures, captures 30
    /// more in Simulator" (`kept` > 0: only part is reused), "Reuses the
    /// last captures".
    private static func captureTitle(plan: AutopilotPlan, screens: Int, kept: Int, toCapture: Int, records: Bool) -> String {
        if kept > 0 {
            return records
                ? String(localized: "Reuses \(kept) captures, captures \(toCapture) more and records the App Preview in Simulator")
                : String(localized: "Reuses \(kept) captures, captures \(toCapture) more in Simulator")
        }
        return switch (toCapture > 0, records) {
        // The assistant picks them once it starts.
        case (true, true) where plan.awaitsScreens: String(localized: "Captures the screens and records the App Preview in Simulator")
        case (true, false) where plan.awaitsScreens: String(localized: "Captures the screens in Simulator")
        case (true, true): String(localized: "Captures \(screens) screens and records the App Preview in Simulator")
        case (true, false) where screens == 1: String(localized: "Captures 1 screen in Simulator")
        case (true, false): String(localized: "Captures \(screens) screens in Simulator")
        case (false, true): String(localized: "Records the App Preview in Simulator")
        case (false, false): String(localized: "Reuses the last captures")
        }
    }

    /// "It also fills a gap: Lumen’s iPad screens exist in only 4
    /// languages today, so this run captures the other 14 and no screenshot
    /// shows the English interface under a translated caption."
    static func gapSentence(_ gaps: [AutopilotInterfaceGap], plan: AutopilotPlan, app: String?) -> String? {
        guard !gaps.isEmpty, plan.capturesEachLanguage else { return nil }
        let before = AutopilotInterfaceGap.before(gaps, app: app ?? String(localized: "the app"))
        let missing = Set(gaps.map(\.missingCount))
        let others = switch missing.count == 1 ? missing.first : nil {
        case 1?: String(localized: "so this run captures the other one")
        case let count?: String(localized: "so this run captures the other \(count)")
        case nil: String(localized: "so this run captures the others")
        }
        let primary = StoreLocaleCatalog.locale(code: plan.primaryLocale)?.shortName ?? plan.primaryLocale
        return String(localized: """
        It also fills a gap: \(before) today, \(others) and no screenshot shows the \(primary) interface under a translated caption.
        """)
    }

    private static func designRow(plan: AutopilotPlan, design: DesignProjectKind, brand: String?) -> GuidedTimelineRow {
        let extras = plan.alsoMakes
        var parts: [String] = []
        if plan.makesScreenshots, plan.screenshotStyle != .keep {
            let count = plan.screenshotStyle == .templates ? max(1, plan.screenshotTemplates.count) : AutopilotRun.directionCount
            parts.append(count == 1 ? String(localized: "1 screenshot look") : String(localized: "\(count) screenshot looks"))
        }
        if !plan.artworkKinds.isEmpty {
            let count = AutopilotRun.proposesConcepts(plan: plan, design: design) ? extras.conceptCount : AutopilotRun.directionCount
            let headers = count == 1 ? String(localized: "1 header") : String(localized: "\(count) headers")
            parts.append(extras.makesMotion ? String(localized: "\(headers) with their loops") : headers)
        }
        if !plan.previewDisplays.isEmpty { parts.append(String(localized: "the App Preview’s captions")) }
        let designer = design.usesDesignAI ? design.title : String(localized: "AppLocalizer")
        let title = parts.isEmpty
            ? String(localized: "Keeps your current look, with the new captures and captions")
            : String(localized: "Designs \(parts.formatted(.list(type: .and)))")
        let detail = designDetail(plan: plan, design: design, brand: brand)
        let minutes = AutopilotEstimate.designMinutes(for: design) + AutopilotEstimate.extrasDesignMinutes(for: plan)
        return GuidedTimelineRow(
            kind: .design, who: design.usesDesignAI ? .designer(designer) : .appLocalizer, title: title, detail: detail,
            time: String(localized: "about \(minutes) min")
        )
    }

    /// Where the looks come from: the design project, the app's own design
    /// (no project, the assistant designs), or AppLocalizer's starters.
    private static func designDetail(plan: AutopilotPlan, design: DesignProjectKind, brand: String?) -> String {
        let following = plan.alsoMakes.artworkDirection.isEmpty ? "" : String(localized: ", following what you wrote")
        if let brand, design.usesDesignAI { return String(localized: "In \(brand)\(following).") }
        if design.usesDesignAI {
            return String(localized: "From the app’s own design: its design docs, theme, fonts and icon\(following).")
        }
        guard AutopilotRun.proposesConcepts(plan: plan, design: design) else {
            return String(localized: "From AppLocalizer’s starters, in the app icon’s colors\(following).")
        }
        // The starters are AppLocalizer's, the headers the assistant's.
        let designer = DesignProjectKind.claudeDesign.title
        if plan.makesScreenshots, plan.screenshotStyle != .keep {
            return String(localized: "Screenshot looks from AppLocalizer’s starters, in the app icon’s colors; headers designed by \(designer)\(following).")
        }
        return String(localized: "Headers designed by \(designer), in the app icon’s colors\(following).")
    }

    private static func localizeRow(plan: AutopilotPlan, client: String) -> GuidedTimelineRow {
        let count = plan.localeCodes.count
        let title = count == 1
            ? String(localized: "Checks everything in \(GuidedMakeSummary.primaryName(plan))")
            : String(localized: "Localizes and checks everything in \(count) languages")
        let detail = plan.makesScreenshots
            ? String(localized: "Captions that don’t fit are shortened by \(client); each change is listed for you.")
            : String(localized: "Names and phrases that don’t fit are shortened by \(client); each change is listed for you.")
        return GuidedTimelineRow(
            kind: .localize, who: .appLocalizer, title: title, detail: detail,
            time: String(localized: "about \(GuidedMakeSummary.localizeMinutes(plan)) min")
        )
    }

    // MARK: - Simulator

    /// "Simulator: status bar 9:41, sample data, light appearance".
    static func simulatorLine(_ plan: AutopilotPlan) -> String {
        let setup = plan.simulator
        var parts: [String] = []
        if plan.capturesEachLanguage { parts.append(String(localized: "each language")) }
        if setup.overridesStatusBar { parts.append(String(localized: "status bar 9:41")) }
        if setup.usesSampleData {
            parts.append(String(localized: "sample data"))
        }
        if setup.lightAppearance { parts.append(String(localized: "light appearance")) }
        if setup.grantsPermissions { parts.append(String(localized: "permissions granted")) }
        if !plan.capturesEachLanguage { parts.append(String(localized: "captured in one language")) }
        guard !parts.isEmpty else { return String(localized: "Simulator: as it is") }
        return String(localized: "Simulator: \(parts.joined(separator: ", "))")
    }
}
