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

    /// The app's name in `locale`, as its App Store page has it there (else
    /// the primary language's, else the run's, else the account's): what
    /// the header and search write as the name.
    func appName(in locale: String) -> String {
        if let name = storeTexts.name(for: locale, primary: primaryLocale.code)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty
        {
            return name
        }
        return run?.appName(in: locale, fallback: app.name) ?? app.name
    }

    /// The header and search pages' phrases in `locale`, by their words in
    /// the primary language, as the set's artwork texts have them.
    func artworkPhrases(in locale: String) -> [String: String] {
        screenshots.document?.artworkTexts?.phraseTexts(locale: locale) ?? [:]
    }

    /// The language the pages' phrases are written in.
    var artworkPrimaryLocale: String {
        run?.plan.primaryLocale ?? primaryLocale.code
    }

    /// The saved caption, else the plan's in the primary language.
    func extrasHeadline(slot: Int, locale: String, plan: AutopilotPlan?) -> String {
        if let saved = screenshots.document?.captions.caption(locale: locale, slot: slot)?.headline, !saved.isEmpty { return saved }
        guard let plan, locale == plan.primaryLocale, plan.screens.indices.contains(slot) else { return "" }
        return plan.screens[slot].caption
    }

    /// The header and search artwork's details under the preview, in the
    /// shown language; nil on the live set or without artwork.
    var artworkDetails: StudioArtworkDetails? {
        guard builder.effectiveChoice == .new, device == .iPhone || device == .iPad, let extras = screenshots.document?.extras else { return nil }
        let codes = Set(screenshots.context.localizations.keys.map(\.code))
        return StudioArtworkDetails(extras: extras, locale: selectedLocale) { codes.contains($0) }
    }

    /// The new set's header, search artwork and App Preview in the shown
    /// language, on iPhone and iPad; nil on the live set or without them.
    var extrasPreview: StudioExtrasPreview? {
        guard builder.effectiveChoice == .new, device == .iPhone || device == .iPad,
              let document = screenshots.document, let extras = document.extras, let template = document.template else { return nil }
        let locale = selectedLocale
        var result = StudioExtrasPreview()
        if let size = extras.artworkSize {
            // A run that made only one of them leaves the other place empty.
            result.header = size.headerKind.map { artworkItem(extras.place($0), template: template, locale: locale) }
            result.search = size.searchKind.map { artworkItem(extras.place($0), template: template, locale: locale) }
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

    /// A place's image as it was drawn. The header shows no phone; the 16:9
    /// image and search the search screen's. A Claude Design page shows the
    /// screens it names.
    func artworkItem(_ place: ExtrasArtworkPlace, template: ScreenshotTemplate, locale: String) -> StudioArtworkItem {
        let shows = place.shows ?? .phone
        let slots = place.page.map(AutopilotArtworkPages.slots) ?? (place.kind != .header && shows.needsCaptures ? [place.searchSlot] : [])
        return StudioArtworkItem(
            kind: place.kind, template: place.template ?? template, locale: locale,
            headline: artworkHeadline(ArtworkTextRole.role(for: place.kind), locale: locale), slots: slots,
            captures: setCaptures(slots, locale: locale), shows: shows, isMotion: place.motion == .loop, page: place.page
        )
    }
}
