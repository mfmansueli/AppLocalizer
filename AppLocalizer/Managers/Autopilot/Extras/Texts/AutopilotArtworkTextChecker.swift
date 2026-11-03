//
//  AutopilotArtworkTextChecker.swift
//  AppLocalizer
//

import Foundation

/// Which placements' texts the assistant writes before the artwork is
/// made: every language's search headline, and any text that doesn't fit
/// its image at the smallest size the direction's look allows. Word and
/// character counts only warn (`ArtworkChecker`), they don't hold the run.
struct AutopilotArtworkTextChecker {
    let template: ScreenshotTemplate
    let texts: ArtworkTextBook
    let size: AutopilotArtworkSize
    let catalog: ScreenshotFontCatalog
    /// What the search artwork shows: a scene's headline is bigger.
    var shows: AutopilotArtworkShow = .phone

    func needs(locales: [String]) -> [AutopilotArtworkTextNeed] {
        let engine = ArtworkLayoutEngine(catalog: catalog)
        return locales.flatMap { code -> [AutopilotArtworkTextNeed] in
            guard let locale = StoreLocaleCatalog.locale(code: code) else { return [] }
            return ArtworkTextRole.roles(for: size).compactMap { role in
                let headline = texts.headline(role, locale: code)
                guard !headline.isEmpty else {
                    return role.isOptional ? nil : AutopilotArtworkTextNeed(locale: code, role: role, problem: .missing)
                }
                let layout = engine.layout(template, kind: role.kind(for: size), locale: locale, headline: headline, slots: [0], shows: shows)
                return layout.headlineFits ? nil : AutopilotArtworkTextNeed(locale: code, role: role, problem: .tooLong, headline: headline)
            }
        }
    }
}
