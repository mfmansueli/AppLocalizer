//
//  StarterDirectionMaker.swift
//  AppLocalizer
//

import Foundation

/// Design without a design project: AppLocalizer's three simple starters,
/// colored from the app icon.
@MainActor
struct StarterDirectionMaker {
    let context: AutopilotContext
    let now: () -> Date

    /// The starters' directions: the three simple ones, or with a
    /// Screenshot style of templates, one per template the person picked,
    /// named "<Template> · for <App>".
    func directions(for run: AutopilotRun) async -> [AutopilotDirection] {
        let palette = await IconPalette.palette(for: context.app.icon)
        let picked = run.plan.makesScreenshots && run.plan.screenshotStyle == .templates ? Self.starters(named: run.plan.screenshotTemplates) : []
        guard picked.isEmpty else {
            return picked.map { starter in
                var template = ScreenshotTemplate.starter(starter, id: context.app.id, title: context.app.name, slotCount: run.plan.screens.count)
                if let palette { Self.color(&template, as: starter, with: palette) }
                return AutopilotDirection(
                    id: "starter-\(starter.rawValue)", name: AutopilotShotStyle.directionName(template: starter.title, app: context.app.name),
                    rationale: String(localized: "From the \(starter.title) template, in \(palette == nil ? String(localized: "its own colors") : String(localized: "the app icon’s colors"))."),
                    source: .none, template: template, receivedAt: now()
                )
            }
        }
        return TemplateStarter.simple.map { starter in
            var template = ScreenshotTemplate.starter(starter, id: context.app.id, title: context.app.name, slotCount: run.plan.screens.count)
            if let palette { Self.color(&template, as: starter, with: palette) }
            return AutopilotDirection(
                id: "starter-\(starter.rawValue)", name: starter.title, rationale: rationale(for: starter, colored: palette != nil),
                source: .none, template: template, receivedAt: now()
            )
        }
    }

    /// The gallery templates with these titles, in order.
    static func starters(named names: [String]) -> [TemplateStarter] {
        names.compactMap { name in TemplateStarter.allCases.first { $0.title.localizedCaseInsensitiveCompare(name) == .orderedSame } }
    }

    /// Keep the current template: the set's template as it is ("Template
    /// v4"), with the new captures and captions; nil when the set has none.
    func keptDirection(for _: AutopilotRun) async -> AutopilotDirection? {
        guard let document = try? await context.services.loadDocument(for: context.app, primaryLocale: context.primaryLocale),
              let template = document.template
        else { return nil }
        let version = document.history?.currentNumber ?? 1
        return AutopilotDirection(
            id: "kept-v\(version)", name: String(localized: "Template v\(version)"),
            rationale: String(localized: "Your current template, with the new captures and captions."), source: .none,
            template: template, receivedAt: now()
        )
    }

    private func rationale(for starter: TemplateStarter, colored: Bool) -> String {
        let app = context.app.name
        guard colored else { return String(localized: "AppLocalizer’s starter, in its own colors.") }
        return switch starter {
        case .above: String(localized: "AppLocalizer’s starter, in the colors of \(app)’s app icon.")
        case .band: String(localized: "AppLocalizer’s starter, with the icon’s darkest color for the band.")
        case .panorama: String(localized: "AppLocalizer’s starter, with a gradient picked from the icon.")
        default: String(localized: "AppLocalizer’s template, in its own colors.")
        }
    }

    /// Recolors a simple starter from the icon; the gallery's other
    /// templates keep their own colors.
    static func color(_ template: inout ScreenshotTemplate, as starter: TemplateStarter, with palette: IconPalette) {
        switch starter {
        case .above:
            template.background.stops = palette.gradient
        case .band:
            template.background.stops = [palette.darkest]
            template.caption.band.color = palette.darkest
        case .panorama:
            template.background.stops = palette.panorama
            template.caption.ink = palette.darkest
        default:
            break
        }
    }
}
