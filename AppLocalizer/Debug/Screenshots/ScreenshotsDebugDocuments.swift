//
//  ScreenshotsDebugDocuments.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The sample documents and live sets behind each Screenshots scenario.
enum ScreenshotsDebugDocuments {
    static func document(for scenario: ScreenshotsDebugScenario) -> ScreenshotsDocument {
        let data = ScreenshotsSampleData.self
        switch scenario {
        case .standard:
            return standard
        case .failedChecks:
            return failedChecks
        case .thaiAndVietnamese:
            return thaiAndVietnamese
        case .noCaptures:
            return .empty(primary: data.primary)
        case .everyDevice:
            return DebugEveryDevice.document
        case .noTemplate:
            var scope = LocaleScope(primary: data.primary)
            scope.setLocalized(data.capturedLocales[.iPhone] ?? [])
            return ScreenshotsDocument(
                captions: data.captions(for: [data.primary]), captures: data.captures, scope: scope, slotNames: data.slotNames
            )
        }
    }

    static var standard: ScreenshotsDocument {
        let data = ScreenshotsSampleData.self
        var scope = LocaleScope(primary: data.primary)
        scope.setLocalized(data.scope)
        return ScreenshotsDocument(
            history: data.history, captions: data.captions(for: data.scope), captures: data.captures, scope: scope,
            slotNames: data.slotNames, pushed: pushed, proposals: data.proposals
        )
    }

    /// The brand font without Thai or Vietnamese, both in the scope with
    /// machine-translated captions, and an iPad capture in Korean's iPhone
    /// slot 4.
    static var failedChecks: ScreenshotsDocument {
        let data = ScreenshotsSampleData.self
        var document = thaiAndVietnamese
        var template = data.template
        template.fonts.display = "Northpier Display"
        template.caption.headline.font = "Northpier"
        template.fonts.fallback[.thai] = nil
        template.fonts.fallback[.vietnamese] = nil
        document.history?.save(template, date: data.date(month: 10, day: 26), note: "Northpier brand font")
        return document
    }

    /// Thai and Vietnamese added with machine-translated captions, and an
    /// iPad capture in Korean's iPhone slot 4.
    static var thaiAndVietnamese: ScreenshotsDocument {
        let data = ScreenshotsSampleData.self
        var document = standard
        document.scope.setLocalized(data.scope + ["th", "vi"])
        for locale in ["th", "vi"] {
            for slot in data.slotNames.indices {
                document.captions.setCaption(data.caption(locale: locale, slot: slot, source: data.provenance), locale: locale, slot: slot)
            }
        }
        document.captures.add(data.capture(locale: "ko", display: .iPhone, slot: 3, pixelSize: PixelSize(width: 2064, height: 2752)))
        return document
    }

    // MARK: - Live

    /// Eight localized sets live from template v4 on both display types
    /// (German slot 3 with its old caption), English (U.K.) uploaded by
    /// hand, and App Previews for English (U.S.) and Japanese on iPhone.
    static var live: LiveScreenshots {
        let data = ScreenshotsSampleData.self
        var sets: [LiveScreenshotSet] = []
        for display in ScreenshotDisplayType.rendered {
            for locale in data.liveLocales {
                let shots = data.slotNames.indices.map { slot in
                    LiveScreenshot(id: "live|\(locale)|\(display.rawValue)|\(slot)", fileName: "", checksum: checksum(locale, display, slot))
                }
                sets.append(LiveScreenshotSet(id: "set|\(locale)|\(display.rawValue)", locale: locale, displayType: display, screenshots: shots))
            }
            let legacy = data.slotNames.indices.map { slot in
                LiveScreenshot(id: "legacy|en-GB|\(display.rawValue)|\(slot)", fileName: "", checksum: "legacy-\(display.rawValue)-\(slot)")
            }
            sets.append(LiveScreenshotSet(id: "set|en-GB|\(display.rawValue)", locale: "en-GB", displayType: display, screenshots: legacy))
        }
        let previews = ["en-US", "ja"].map { locale in
            LiveAppPreviewSet(id: "preview|\(locale)", locale: locale, displayType: .iPhone, previewCount: 1, durationSeconds: 24)
        }
        return LiveScreenshots(screenshotSets: sets, previewSets: previews)
    }

    /// What AppLocalizer pushed on Oct 12: the eight live sets' renders.
    static var pushed: [PushedRender] {
        let data = ScreenshotsSampleData.self
        let template = data.template
        let captures = data.captures
        var pushed: [PushedRender] = []
        for display in ScreenshotDisplayType.rendered {
            for locale in data.liveLocales {
                for slot in data.slotNames.indices {
                    var caption = data.caption(locale: locale, slot: slot, source: data.provenance)
                    if locale == "de-DE", slot == 2 { caption?.headline = data.liveGermanSearchCaption }
                    let capture = captures.capture(locale: locale, displayType: display, slot: slot, primary: data.primary)
                    let key = RenderKey(
                        templateHash: template.contentHash, locale: locale, displayType: display, slot: slot,
                        caption: caption, captureID: capture?.capture.id
                    )
                    let cell = ScreenshotCellKey(locale: locale, displayType: display, slot: slot)
                    pushed.append(PushedRender(cell: cell, renderKey: key, checksum: checksum(locale, display, slot), date: data.liveDate))
                }
            }
        }
        return pushed
    }

    private static func checksum(_ locale: String, _ display: ScreenshotDisplayType, _ slot: Int) -> String {
        "sample-\(locale)-\(display.rawValue)-\(slot)"
    }

    /// The locale, display type and slot of one of English (U.K.)'s
    /// hand-uploaded screenshots.
    static func legacySource(for id: String) -> ScreenshotCellKey? {
        let parts = id.split(separator: "|").map(String.init)
        guard parts.count == 4, parts[0] == "legacy", let display = ScreenshotDisplayType(rawValue: parts[2]), let slot = Int(parts[3]) else { return nil }
        return ScreenshotCellKey(locale: parts[1], displayType: display, slot: slot)
    }
}
#endif
