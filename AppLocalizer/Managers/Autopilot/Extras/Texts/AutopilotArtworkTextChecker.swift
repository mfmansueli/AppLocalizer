//
//  AutopilotArtworkTextChecker.swift
//  AppLocalizer
//

import Foundation

/// Which placements' texts the assistant writes before the artwork is
/// made: every language's search headline and the pages' phrases in every
/// language, and any text that doesn't fit its image at the smallest size
/// the direction's look allows. Word and character counts only warn
/// (`ArtworkChecker`), they don't hold the run.
struct AutopilotArtworkTextChecker {
    let template: ScreenshotTemplate
    let texts: ArtworkTextBook
    let size: AutopilotArtworkSize
    let catalog: ScreenshotFontCatalog
    /// What the search artwork shows: a scene's headline is bigger.
    var shows: AutopilotArtworkShow = .phone
    /// The language the pages' phrases are written in.
    var primaryLocale = ""

    /// A page in one language, measured without drawing: its headline and
    /// its phrases there (`ArtworkTextBook.phraseTexts`).
    typealias Measure = @MainActor (
        _ html: String, _ kind: AutopilotArtworkKind, _ locale: StoreLocale, _ headline: String, _ phrases: [String: String]
    ) async -> ArtworkWebMeasure?

    /// With a direction's Claude Design pages: a text is too long when the
    /// page can't fit it (`measure` renders it without drawing), and a
    /// phrase is missing in a language that doesn't have its words; a
    /// canvas without a page is checked with AppLocalizer's own layout.
    @MainActor
    func needs(locales: [String], design: AutopilotArtworkDesign, measure: Measure) async -> [AutopilotArtworkTextNeed] {
        var needs: [AutopilotArtworkTextNeed] = []
        let engine = ArtworkLayoutEngine(catalog: catalog)
        for code in locales {
            guard let locale = StoreLocaleCatalog.locale(code: code) else { continue }
            // A phrase on both pages is written once per language.
            var phrasesSeen: Set<String> = []
            for role in ArtworkTextRole.roles(for: size) {
                let headline = texts.headline(role, locale: code)
                if headline.isEmpty, !role.isOptional { needs.append(AutopilotArtworkTextNeed(locale: code, role: role, problem: .missing)) }
                let kind = role.kind(for: size)
                guard let html = design.page(for: kind) else {
                    let layout = engine.layout(template, kind: kind, locale: locale, headline: headline, slots: [0], shows: shows)
                    if !headline.isEmpty, !layout.headlineFits {
                        needs.append(AutopilotArtworkTextNeed(locale: code, role: role, problem: .tooLong, headline: headline))
                    }
                    continue
                }
                guard let measured = await measure(html, kind, locale, headline, texts.phraseTexts(locale: code)) else { continue }
                if !headline.isEmpty, !measured.headlineFits {
                    needs.append(AutopilotArtworkTextNeed(locale: code, role: role, problem: .tooLong, headline: headline))
                }
                needs += phraseNeeds(measured, locale: code, role: role, seen: &phrasesSeen)
            }
        }
        return needs
    }

    /// The page's phrases a language lacks, or whose words there don't fit
    /// even at their smallest.
    private func phraseNeeds(
        _ measure: ArtworkWebMeasure, locale: String, role: ArtworkTextRole, seen: inout Set<String>
    ) -> [AutopilotArtworkTextNeed] {
        measure.elements(.text).compactMap { element in
            let source = ArtworkTextBook.phraseKey(element.source ?? element.text ?? "")
            guard !source.isEmpty, seen.insert(source).inserted else { return nil }
            if element.isMissingLanguage == true, locale != primaryLocale {
                return AutopilotArtworkTextNeed(locale: locale, role: role, problem: .missing, phrase: source)
            }
            guard !element.fits else { return nil }
            return AutopilotArtworkTextNeed(locale: locale, role: role, problem: .tooLong, headline: element.text ?? "", phrase: source)
        }
    }

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
