//
//  ArtworkChecker+Page.swift
//  AppLocalizer
//

import Foundation

extension ArtworkChecker {
    /// A Claude Design page's own problems: no place for the placement's
    /// text, a capture that didn't load (an error: the image would show an
    /// empty frame), a page bigger than its canvas, its own words, and
    /// text that moves in a loop.
    func pageChecks(_ input: ArtworkCheckInput) -> [ArtworkCheck] {
        var checks: [ArtworkCheck] = []
        if let page = input.page {
            // A page that writes its own phrases (a header concept) needs no
            // place for the placement's text, and with no text there's
            // nothing to show: Bruma's concepts were told so on every render.
            let hasLine = !input.line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if page.elements(.headline).isEmpty, hasLine, page.elements(.text).isEmpty {
                checks.append(ArtworkCheck(
                    kind: .page,
                    text: String(localized: "\(input.place): the page has no data-al=\"headline\", so the placement’s own text never shows.")
                ))
            }
            let broken = page.elements(.capture).filter { $0.isLoaded == false }.compactMap(\.slot)
            if !broken.isEmpty {
                let slots = broken.map(String.init).formatted(.list(type: .and))
                checks.append(ArtworkCheck(
                    kind: .page, severity: .error,
                    text: String(localized: "\(input.place): the capture of screen \(slots) didn’t load, so it shows an empty frame.")
                ))
            }
            checks += textChecks(page, input: input)
            let size = input.kind.pixelSize
            if page.contentWidth > Double(size.width) + 1 || page.contentHeight > Double(size.height) + 1 {
                checks.append(ArtworkCheck(
                    kind: .page,
                    text: String(localized: "\(input.place): the page reaches past its \(size.title) canvas, so what’s beyond the edge is cut off.")
                ))
            }
        }
        if !input.geometry.moving.isEmpty {
            let parts = input.geometry.moving.formatted(.list(type: .and))
            checks.append(ArtworkCheck(
                kind: .loop, severity: .warning,
                text: String(localized: "\(input.place): \(parts) move in the loop; keep the text and icon still so they read at a glance.")
            ))
        }
        return checks
    }

    /// The page's phrases (`data-al="text"`): one not yet in this language
    /// doesn't read in it (an error, unless Localize translates it later),
    /// and one that runs out of its box.
    private func textChecks(_ page: ArtworkWebMeasure, input: ArtworkCheckInput) -> [ArtworkCheck] {
        var checks: [ArtworkCheck] = []
        let missing = page.elements(.text).filter { $0.isMissingLanguage == true }
        if !missing.isEmpty, !input.phrasesTranslateLater {
            checks.append(ArtworkCheck(
                kind: .page, severity: .error,
                text: String(localized: """
                \(input.place): \(missing.count) of the page’s phrases aren’t in \(input.locale.name) yet, so they don’t \
                read in it. Write them in Captions.
                """)
            ))
        }
        if let long = page.texts.first(where: { !$0.fits }) {
            checks.append(ArtworkCheck(
                kind: .page,
                text: String(localized: "\(input.place): ‘\(ArtworkCheckGeometry.snippet(long.text ?? ""))’ runs out of its box; give it room or data-al-fit.")
            ))
        }
        return checks
    }
}
