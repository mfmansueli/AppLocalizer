//
//  AutopilotArtworkPages.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// What a run's Claude Design page is rendered with in one language: the
/// captures its `data-slot`s name (that language's, else the primary
/// one's; the pick before the captures are made), the app's icon, its
/// name in that language's App Store page, and the placement's text.
@MainActor
struct AutopilotArtworkPages {
    let context: AutopilotContext

    /// The slots (0-based) a page's captures name: `data-slot="N"`, slot 1
    /// for a capture without one.
    static func slots(in html: String) -> [Int] {
        var slots: Set<Int> = []
        let marker = ArtworkWebMarker.capture.attribute
        var rest = html[...]
        while let found = rest.range(of: marker) {
            let tag = rest[found.upperBound...].prefix { $0 != ">" }
            let start = rest[..<found.lowerBound].lastIndex(of: "<").map { String(rest[$0..<found.lowerBound]) } ?? ""
            slots.insert((slot(in: String(tag)) ?? slot(in: start) ?? 1) - 1)
            rest = rest[found.upperBound...]
        }
        return slots.filter { $0 >= 0 }.sorted()
    }

    private static func slot(in tag: String) -> Int? {
        guard let range = tag.range(of: "data-slot=") else { return nil }
        let digits = tag[range.upperBound...].drop { $0 == "\"" || $0 == "'" }.prefix(while: \.isNumber)
        return Int(digits)
    }

    /// The request for `html` on `kind` in `locale`, with the page's
    /// `phrases` in that language (`ArtworkTextBook.phraseTexts`); without
    /// `withCaptures` (only the text's fit is wanted) no capture is loaded.
    func request(
        html: String, kind: AutopilotArtworkKind, locale: StoreLocale, headline: String, run: AutopilotRun, icon: Data?,
        pixelWidth: Int? = nil, withCaptures: Bool = true, phrases: [String: String] = [:]
    ) async -> ArtworkWebRequest {
        let captures = withCaptures ? await captures(Self.slots(in: html), locale: locale.code, run: run) : [:]
        return ArtworkWebRequest(
            html: html, kind: kind, locale: locale.code, isRightToLeft: locale.isRTL || ScreenshotScript(locale: locale).isRightToLeft,
            headline: headline, appName: run.appName(in: locale.code, fallback: context.app.name), captures: captures, icon: icon,
            pixelWidth: pixelWidth, primaryLocale: run.plan.primaryLocale, phrases: phrases
        )
    }

    /// Each slot's iPhone capture in `locale` as PNG: the language's own,
    /// else the primary language's, else the pick.
    func captures(_ slots: [Int], locale: String, run: AutopilotRun) async -> [Int: Data] {
        var found: [Int: Data] = [:]
        for slot in slots where run.plan.screens.indices.contains(slot) {
            let screen = run.plan.screens[slot].id
            let own = AutopilotCaptureTarget(screenID: screen, displayType: .iPhone, locale: locale)
            let primary = AutopilotCaptureTarget(screenID: screen, displayType: .iPhone, locale: run.plan.primaryLocale)
            guard let capture = run.finalCapture(for: own) ?? run.finalCapture(for: primary) ?? run.pickedCapture(for: screen),
                  let image = await context.services.captureImage(
                      capture.screenshotCapture(slot: slot), for: context.app, pixelWidth: AutopilotArtworkMaker.captureWidth
                  )
            else { continue }
            found[slot] = ScreenshotPNG.data(image)
        }
        return found
    }

    /// The app's icon as PNG, once per batch of renders.
    func icon() async -> Data? {
        await ArtworkIcon.image(of: context.app).flatMap(ScreenshotPNG.data)
    }
}
