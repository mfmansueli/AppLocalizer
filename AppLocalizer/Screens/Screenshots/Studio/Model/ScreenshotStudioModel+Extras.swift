//
//  ScreenshotStudioModel+Extras.swift
//  AppLocalizer
//

import Foundation

/// The extras' thumbnails: which captures and captions the header, search
/// artwork and App Preview poster show, from the run before Localize
/// (its picks) and from the saved set after.
extension ScreenshotStudioModel {
    /// The run's picked capture for each slot, front first.
    func pickedCaptures(_ slots: [Int], run: AutopilotRun) -> [Int: ScreenshotCapture] {
        var captures: [Int: ScreenshotCapture] = [:]
        for slot in slots where run.plan.screens.indices.contains(slot) {
            captures[slot] = run.pickedCapture(for: run.plan.screens[slot].id)?.screenshotCapture(slot: slot)
        }
        return captures
    }

    /// The saved set's iPhone capture for each slot in `locale`, else the
    /// primary language's.
    func setCaptures(_ slots: [Int], locale: String) -> [Int: ScreenshotCapture] {
        guard let document = screenshots.document else { return [:] }
        var captures: [Int: ScreenshotCapture] = [:]
        for slot in slots {
            captures[slot] = document.captures.capture(locale: locale, displayType: .iPhone, slot: slot, primary: primaryLocale.code)?.capture
        }
        return captures
    }

    /// A placement's text in `locale`: the saved one; before Localize
    /// writes it, the search image shows the subtitle as a stand-in and the
    /// header none.
    func artworkHeadline(_ role: ArtworkTextRole, locale: String) -> String {
        let saved = screenshots.document?.artworkTexts?.headline(role, locale: locale) ?? ""
        guard saved.isEmpty, role == .search else { return saved }
        return storeTexts.subtitle(for: locale, primary: primaryLocale.code) ?? ""
    }

    /// The saved caption, else the plan's in the primary language.
    func extrasHeadline(slot: Int, locale: String, plan: AutopilotPlan?) -> String {
        if let saved = screenshots.document?.captions.caption(locale: locale, slot: slot)?.headline, !saved.isEmpty { return saved }
        guard let plan, locale == plan.primaryLocale, plan.screens.indices.contains(slot) else { return "" }
        return plan.screens[slot].caption
    }

    /// The new set's header, search artwork and App Preview in the shown
    /// language, on iPhone and iPad; nil on the live set or without them.
    var extrasPreview: StudioExtrasPreview? {
        guard builder.effectiveChoice == .new, device == .iPhone || device == .iPad,
              let document = screenshots.document, let extras = document.extras, let template = document.template else { return nil }
        let locale = selectedLocale
        var result = StudioExtrasPreview()
        if let size = extras.artworkSize {
            let headerKind: AutopilotArtworkKind = size == .wide ? .wide : .header
            let searchKind: AutopilotArtworkKind = size == .wide ? .wide : .search
            let look = extras.artworkTemplate ?? template
            let shows = extras.artworkShows ?? .phone
            let isMotion = extras.artworkMotion == .loop
            // The header shows no phone; the 16:9 image and search the search screen's.
            let headerSlots = size == .wide && shows.needsCaptures ? [extras.searchSlot] : []
            result.header = StudioArtworkItem(
                kind: headerKind, template: look, locale: locale, headline: artworkHeadline(ArtworkTextRole.role(for: headerKind), locale: locale),
                slots: headerSlots, captures: setCaptures(headerSlots, locale: locale), shows: shows, isMotion: isMotion
            )
            let searchSlots = shows.needsCaptures ? [extras.searchSlot] : []
            result.search = StudioArtworkItem(
                kind: searchKind, template: look, locale: locale,
                headline: artworkHeadline(.search, locale: locale),
                slots: searchSlots, captures: setCaptures(searchSlots, locale: locale), shows: shows, isMotion: isMotion
            )
        }
        if let file = extras.preview(on: device, locale: locale, primary: primaryLocale.code) {
            let language = StoreLocaleCatalog.locale(code: file.locale)?.name ?? file.locale
            result.appPreview = StudioPreviewTile(
                template: extras.previewTemplate ?? template, headline: extrasHeadline(slot: 0, locale: file.locale, plan: run?.plan),
                capture: setCaptures([0], locale: file.locale)[0], length: file.lengthTitle,
                chip: file.locale == locale ? String(localized: "New") : language,
                file: file
            )
        }
        return result
    }
}
