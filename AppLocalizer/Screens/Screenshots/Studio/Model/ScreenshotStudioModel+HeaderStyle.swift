//
//  ScreenshotStudioModel+HeaderStyle.swift
//  AppLocalizer
//

import SwiftUI

/// The plan's Header style (scene templates, or the design AI going
/// freely) and Screenshot style (its own directions, gallery templates,
/// or the current template kept).
extension ScreenshotStudioModel {
    // MARK: - Header style

    /// The header and search come as concepts: a design AI designs them.
    var proposesHeaderConcepts: Bool {
        guard let plan = run?.plan else { return false }
        return AutopilotRun.proposesConcepts(plan: plan, design: designProject?.kind ?? .none)
    }

    /// The design source's name: "Claude Design".
    var headerDesignerName: String {
        let kind = designProject?.kind ?? .none
        return kind.usesDesignAI ? kind.title : DesignProjectKind.claudeDesign.title
    }

    func setArtworkStyle(_ style: AutopilotArtworkStyle) {
        updatePlan { plan in
            plan.alsoMakes.artworkStyle = style
            if style == .templates, plan.alsoMakes.templates == nil {
                plan.alsoMakes.headerTemplates = AutopilotHeaderTemplate.defaultPicks(recommended: self.headerRecommendation.template)
            }
        }
    }

    /// Adds `template`, or takes it out: a fourth replaces the last.
    func toggleHeaderTemplate(_ template: AutopilotHeaderTemplate) {
        let picks = headerTemplatePicks
        updatePlan { $0.alsoMakes.headerTemplates = AutopilotHeaderTemplate.toggling(template, in: picks) }
    }

    /// The picks, in order: the plan's, else the first three with the
    /// recommended one first.
    var headerTemplatePicks: [AutopilotHeaderTemplate] {
        guard let picks = run?.plan.alsoMakes.templates else {
            return AutopilotHeaderTemplate.defaultPicks(recommended: headerRecommendation.template)
        }
        return picks
    }

    /// Fills in the first picks the plan shows, before Start.
    func fillHeaderTemplates() {
        guard let plan = run?.plan, plan.alsoMakes.artworkStyle == .templates, plan.alsoMakes.templates == nil else { return }
        let picks = headerTemplatePicks
        updatePlan { $0.alsoMakes.headerTemplates = picks }
    }

    /// Claude Code's recommendation from its scan, else AppLocalizer's
    /// guess.
    var headerRecommendation: AutopilotHeaderRecommendation {
        appSupport?.profile(for: app.id)?.look?.headerRecommendation
            ?? AutopilotHeaderRecommendation.guess(categories: [], client: assistantTitle)
    }

    /// "Claude Code".
    var assistantTitle: String {
        appSupport?.profile(for: app.id)?.reportedBy ?? String(localized: "Claude Code")
    }

    /// "Pick up to 3 (a 4th replaces the last). Claude Design adapts each
    /// one to Lumen, and you choose 1 of the results. 3 of 3 picked."
    var headerTemplatesNote: String {
        let count = headerTemplatePicks.count
        let lead = String(localized: "Pick up to 3 (a 4th replaces the last). \(headerDesignerName) adapts each one to \(app.name), and you choose 1 of the results. ")
        return lead + (count > 0 ? String(localized: "\(count) of 3 picked.") : String(localized: "Pick at least one."))
    }

    /// Go freely's line.
    var headerFreeText: String {
        String(localized: """
        \(headerDesignerName) studies \(app.name) and proposes 3 concepts of its own, each a different metaphor from the \
        app’s world. You see them in the Design step as they arrive, with a still of each to choose from.
        """)
    }

    /// "What Claude Design gets from the scan": what the app does, its look,
    /// the screens, the brand and the person's direction.
    var headerScanRows: [(key: String, value: String)] {
        let look = appSupport?.profile(for: app.id)?.look
        let primary = run?.plan.primaryLocale ?? ""
        let subtitle = storeTexts.subtitle(for: primary, primary: primary) ?? ""
        let does = look?.whatItDoes ?? (subtitle.isEmpty ? String(localized: "Read from the App Store page and the project") : subtitle)
        var lookParts: [String] = []
        if let icon = look?.iconDescription { lookParts.append(String(localized: "Icon: \(icon)")) }
        let colors = ([look?.accentColor].compactMap(\.self) + (look?.themeColors ?? [])).prefix(4)
        if !colors.isEmpty { lookParts.append(colors.joined(separator: ", ")) }
        if let fonts = look?.fonts, !fonts.isEmpty { lookParts.append(fonts.formatted(.list(type: .and))) }
        if look?.supportsDarkMode == true { lookParts.append(String(localized: "dark mode")) }
        let screens = run?.plan.screens.count ?? 0
        let languages = run?.plan.localeCodes.count ?? 0
        let direction = run?.plan.alsoMakes.artworkDirection ?? AutopilotArtworkDirection()
        var asked: [String] = []
        if !direction.trimmedText.isEmpty { asked.append("“\(direction.trimmedText)”") }
        let references = direction.references.count
        if references > 0 { asked.append(references == 1 ? String(localized: "1 reference") : String(localized: "\(references) references")) }
        return [
            (String(localized: "What it does"), does),
            (String(localized: "Its look"), lookParts.isEmpty ? String(localized: "The icon’s colors; the rest once \(assistantTitle) has scanned the project") : lookParts.joined(separator: " · ")),
            (String(localized: "Screens"), String(localized: "\(screens) screens and their captions in \(languages) languages")),
            (String(localized: "Brand"), designProject.map { String(localized: "\($0.displayName) in \($0.kind.title)") } ?? String(localized: "The app’s icon and theme")),
            (String(localized: "Your direction"), asked.isEmpty ? String(localized: "None yet; add it under Expected result") : asked.joined(separator: " · ")),
        ]
    }

    /// Reads the icon's colors once, for the template previews.
    func loadHeaderColors() async {
        guard headerColors == nil else { return }
        headerColors = await IconPalette.palette(for: app.icon)
    }

    /// The previews' two colors: the icon's, else indigo.
    var headerSketchColors: (light: Color, dark: Color) {
        let light = headerColors.flatMap { TemplateColor($0.light) }?.color ?? Color(red: 0.36, green: 0.33, blue: 0.91)
        let dark = headerColors.flatMap { TemplateColor($0.dark) }?.color ?? Color(red: 0.17, green: 0.15, blue: 0.41)
        return (light, dark)
    }

    // MARK: - Screenshot style

    func setShotStyle(_ style: AutopilotShotStyle) {
        updatePlan { $0.runChoice.shotStyle = style }
    }

    /// Adds a gallery template, or takes it out: a fourth replaces the last.
    func toggleShotTemplate(_ name: String) {
        let picks = run?.plan.screenshotTemplates ?? []
        updatePlan { $0.runChoice.shotTemplates = AutopilotShotStyle.toggling(name, in: picks) }
    }

    /// The set's template version ("v4"), nil when it has none to keep.
    var keptTemplateVersion: Int? {
        guard screenshots.document?.template != nil else { return nil }
        return screenshots.document?.history?.currentNumber ?? 1
    }

    /// The twelve gallery templates, by title.
    static var shotTemplateNames: [String] {
        TemplateStarter.allCases.map(\.title)
    }
}
