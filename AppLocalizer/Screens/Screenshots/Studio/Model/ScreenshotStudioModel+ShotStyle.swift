//
//  ScreenshotStudioModel+ShotStyle.swift
//  AppLocalizer
//

import Foundation

/// The plan's Screenshot style: the design source's own directions,
/// gallery templates picked in the template picker (shown as previews on
/// the plan), or the current template kept.
extension ScreenshotStudioModel {
    func setShotStyle(_ style: AutopilotShotStyle) {
        updatePlan { $0.runChoice.shotStyle = style }
    }

    /// Adds a gallery template, or takes it out: a fourth replaces the last.
    func toggleShotTemplate(_ starter: TemplateStarter) {
        let picks = run?.plan.screenshotTemplates ?? []
        updatePlan { $0.runChoice.shotTemplates = AutopilotShotStyle.toggling(starter.title, in: picks) }
    }

    /// The picked gallery templates, in the order they were picked.
    var shotTemplatePicks: [TemplateStarter] {
        StarterDirectionMaker.starters(named: run?.plan.screenshotTemplates ?? [])
    }

    /// 1, 2, 3 for a picked template; nil when it isn't picked.
    func shotTemplateNumber(_ starter: TemplateStarter) -> Int? {
        shotTemplatePicks.firstIndex(of: starter).map { $0 + 1 }
    }

    /// The set's template version ("v4"), nil when it has none to keep.
    var keptTemplateVersion: Int? {
        guard screenshots.document?.template != nil else { return nil }
        return screenshots.document?.history?.currentNumber ?? 1
    }

    /// Who makes the directions: the design AI, else AppLocalizer.
    var shotStyleDesigner: String {
        designProject?.kind.usesDesignAI == true ? headerDesignerName : String(localized: "AppLocalizer")
    }

    /// What to make's line: who captures, who designs (in which brand) and
    /// who localizes. Without a design project AppLocalizer designs, so it
    /// doesn't promise a design AI or a brand there isn't.
    var guidedMakeIntro: String {
        guard let brand = shotStyleBrand else {
            return String(localized: "Choose any mix. \(assistantTitle) captures the real app, and AppLocalizer designs, localizes and checks every image.")
        }
        return String(localized: "Choose any mix. \(assistantTitle) captures the real app, \(shotStyleDesigner) designs it in \(brand), and AppLocalizer localizes and checks every image.")
    }

    /// The brand the design AI works in, if any.
    var shotStyleBrand: String? {
        designProject.flatMap { $0.kind.usesDesignAI ? $0.displayName : nil }
    }

    /// The template picker's line under its title.
    var shotTemplatePickerNote: String {
        let inBrand = shotStyleBrand.map { String(localized: " in \($0)") } ?? ""
        return String(localized: """
        From each template you pick, \(shotStyleDesigner) makes one screenshot direction\(inBrand), and you choose one \
        of them. Each template is previewed with \(app.name)’s captions and captures.
        """)
    }

    /// "2 of 3 picked.", and what a fourth does once three are.
    var shotTemplatesPickedText: String {
        let count = shotTemplatePicks.count
        let maximum = AutopilotShotStyle.maximumTemplates
        if count == 0 { return String(localized: "Pick at least one, up to \(maximum).") }
        if count < maximum { return String(localized: "\(count) of \(maximum) picked.") }
        return String(localized: "\(count) of \(maximum) picked. Picking another replaces the last.")
    }
}
