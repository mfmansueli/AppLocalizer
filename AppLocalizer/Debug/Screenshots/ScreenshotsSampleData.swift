//
//  ScreenshotsSampleData.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The design's sample screenshots for Lumen Journal: a version-4 template,
/// captions in twelve locales, fastlane captures of ten interfaces, eight
/// localized sets live from that template plus an English (U.K.) set
/// uploaded by hand, and Claude Code's template and caption proposals
/// (`ScreenshotsSampleData+Proposals`).
enum ScreenshotsSampleData {
    static let primary = "en-US"
    static let slotNames = ["Today", "Week", "Search", "Photos", "Privacy"]
    /// The scope: twelve locales.
    static let scope = ["en-US", "de-DE", "fr-FR", "es-ES", "es-MX", "it", "pt-BR", "ja", "ko", "zh-Hans", "ar-SA", "nl-NL"]
    /// Locales whose interface was captured, per display type.
    static let capturedLocales: [ScreenshotDisplayType: [String]] = [
        .iPhone: ["en-US", "de-DE", "fr-FR", "es-ES", "it", "pt-BR", "ja", "ko", "zh-Hans", "ar-SA"],
        .iPad: ["en-US", "de-DE", "fr-FR", "ja"],
    ]
    /// The display types Lumen has live and kept sets on: iPhone and iPad.
    /// It has no iPhone Duo screenshots yet.
    static let liveDisplays: [ScreenshotDisplayType] = [.iPhone, .iPad]
    /// Live from template v4 on both display types.
    static let liveLocales = ["en-US", "de-DE", "fr-FR", "es-ES", "it", "pt-BR", "ja", "ko"]
    /// German slot 3 went live with a shorter caption than it has now.
    static let liveGermanSearchCaption = "Durchsuche Einträge in Sekunden"
    static let liveDate = date(month: 10, day: 12)

    static func date(month: Int, day: Int, hour: Int = 10, minute: Int = 0) -> Date {
        DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: month, day: day, hour: hour, minute: minute).date ?? .distantPast
    }

    /// Lumen's template: Caption above device, slot 2's headline at 104 u.
    static var template: ScreenshotTemplate {
        var template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen", version: 4)
        template.slots[1].over["caption.headline.size"] = 104
        return template
    }

    /// v1–v4 as the design's history popover lists them, all by you.
    static var history: TemplateHistory {
        history(latest: template, note: "Arabic and Hebrew mirror the layout")
    }

    /// v1–v3, then `latest` as v4.
    static func history(latest: ScreenshotTemplate, note latestNote: String) -> TemplateHistory {
        var first = template
        first.rightToLeft.mirror = false
        first.slots[0].layout = .standard
        first.slots[1].over = [:]
        first.caption.headline.size = 104
        first.caption.headline.min = 76
        var history = TemplateHistory.starting(with: first, date: date(month: 10, day: 5), note: "Created from the starter “Caption above device”")
        var second = first
        second.slots[0].layout = .hero
        history.save(second, date: date(month: 10, day: 8), note: "Slot 1 uses the hero layout with a subhead")
        var third = template
        third.rightToLeft.mirror = false
        history.save(third, date: date(month: 10, day: 11), note: "Headline 112 u, smallest 80 u")
        history.save(latest, date: date(month: 10, day: 12), note: latestNote)
        return history
    }

    /// The legacy look en-GB's hand-uploaded set has.
    static var legacyTemplate: ScreenshotTemplate {
        var template = ScreenshotTemplate.starter(.above, id: "legacy", title: "Legacy")
        template.background = TemplateBackground(kind: .solid, stops: ["#F2F2F4"])
        template.caption.ink = "#1C1C1E"
        template.caption.align = .start
        template.caption.headline = TemplateTextStyle(font: "SF Pro Text", weight: 700, size: 92, min: 92, lineHeight: 1.1, maxLines: 2)
        template.device.width = 0.7
        template.rightToLeft.mirror = false
        template.slots = template.slots.map { _ in TemplateSlot() }
        return template
    }

    static func caption(locale: String, slot: Int, source: (String, Int) -> CaptionProvenance) -> ScreenshotCaption? {
        guard let texts = captionTexts[locale], texts.indices.contains(slot) else { return nil }
        let parts = texts[slot].split(separator: "|", maxSplits: 1).map(String.init)
        return ScreenshotCaption(headline: parts[0], subhead: parts.count > 1 ? parts[1] : nil, provenance: source(locale, slot))
    }

    /// Who wrote each caption: you for English (U.S.) and German slot 3,
    /// machine translation for Spanish (Mexico), two Chinese slots and two
    /// Dutch ones, reviewed translations otherwise.
    static func provenance(locale: String, slot: Int) -> CaptionProvenance {
        switch (locale, slot) {
        case ("en-US", _): .written
        case ("de-DE", 2): .edited
        case ("es-MX", _), ("zh-Hans", 1), ("zh-Hans", 3), ("nl-NL", 0), ("nl-NL", 2), ("th", _), ("vi", _): .machineTranslated
        default: .reviewed
        }
    }

    static func captions(for locales: [String]) -> CaptionBook {
        var book = CaptionBook()
        for locale in locales {
            for slot in 0..<slotNames.count {
                book.setCaption(caption(locale: locale, slot: slot, source: provenance), locale: locale, slot: slot)
            }
        }
        return book
    }

    /// fastlane captures: each captured locale's own, per display type.
    static var captures: CaptureIndex {
        var index = CaptureIndex()
        for (display, locales) in capturedLocales {
            for locale in locales {
                for slot in slotNames.indices {
                    index.add(capture(locale: locale, display: display, slot: slot))
                }
            }
        }
        return index
    }

    static func capture(locale: String, display: ScreenshotDisplayType, slot: Int, pixelSize: PixelSize? = nil) -> ScreenshotCapture {
        let canvas = display.isTablet ? display.portraitPixelSize.rotated : display.portraitPixelSize
        return ScreenshotCapture(
            id: "\(locale)|\(display.rawValue)|\(slot)", locale: locale, displayType: display, slot: slot, source: .fastlane,
            fileName: "\(locale)/\(display.deviceName)-0\(slot + 1)_\(slotNames[slot]).png", pixelSize: pixelSize ?? canvas,
            importedAt: date(month: 10, day: 26, hour: 9, minute: 12)
        )
    }
}
#endif
