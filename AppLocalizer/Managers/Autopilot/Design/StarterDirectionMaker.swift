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

    func directions(for run: AutopilotRun) async -> [AutopilotDirection] {
        let palette = await IconPalette.palette(for: context.app.icon)
        return TemplateStarter.simple.map { starter in
            var template = ScreenshotTemplate.starter(starter, id: context.app.id, title: context.app.name, slotCount: run.plan.screens.count)
            if let palette { Self.color(&template, as: starter, with: palette) }
            return AutopilotDirection(
                id: "starter-\(starter.rawValue)", name: starter.title, rationale: rationale(for: starter, colored: palette != nil),
                source: .none, template: template, receivedAt: now()
            )
        }
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
