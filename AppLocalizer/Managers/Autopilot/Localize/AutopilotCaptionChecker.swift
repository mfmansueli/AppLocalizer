//
//  AutopilotCaptionChecker.swift
//  AppLocalizer
//

import Foundation

/// Lays out one language's captions with a template on each device: the
/// ones that don't fit, or are missing, are what the assistant writes or
/// shortens. Used to check the chosen template and to label directions.
struct AutopilotCaptionChecker {
    let template: ScreenshotTemplate
    let captions: CaptionBook
    let displayTypes: [ScreenshotDisplayType]
    let slotCount: Int
    let primaryLocale: String
    let catalog: ScreenshotFontCatalog

    func check(locale code: String) -> AutopilotLocaleCheck {
        guard let locale = StoreLocaleCatalog.locale(code: code) else {
            return AutopilotLocaleCheck(status: .fits(note: nil), overflows: [])
        }
        let engine = ScreenshotLayoutEngine(catalog: catalog)
        var measured = Measured()
        for display in displayTypes {
            for slot in 0..<slotCount where !measured.overflows.contains(where: { $0.slot == slot }) {
                measure(slot: slot, on: display, locale: locale, engine: engine, into: &measured)
            }
        }
        guard measured.overflows.isEmpty else {
            return AutopilotLocaleCheck(status: .shortening(count: measured.overflows.count), overflows: measured.overflows)
        }
        let note: String? = if let fallbackFont = measured.fallbackFont {
            String(localized: "\(fallbackFont) for \(locale.shortName)")
        } else if measured.isMirrored {
            String(localized: "mirrored for right-to-left")
        } else {
            nil
        }
        return AutopilotLocaleCheck(status: .fits(note: note), overflows: [])
    }

    /// What laying out a language's captions found.
    private struct Measured {
        var overflows: [AutopilotOverflow] = []
        var fallbackFont: String?
        var isMirrored = false
    }

    /// Lays out one slot's caption on one display type. A missing caption
    /// in a translation counts as an overflow, so it gets written.
    private func measure(
        slot: Int, on display: ScreenshotDisplayType, locale: StoreLocale, engine: ScreenshotLayoutEngine, into measured: inout Measured
    ) {
        let maxLines = template.caption.headline.maxLines
        guard let caption = captions.caption(locale: locale.code, slot: slot), !caption.isEmpty else {
            if locale.code != primaryLocale {
                measured.overflows.append(AutopilotOverflow(
                    locale: locale.code, slot: slot, displayType: display, headline: "", maxLines: maxLines, fill: 0
                ))
            }
            return
        }
        let layout = engine.layout(template, slot: slot, locale: locale, displayType: display, caption: caption)
        if layout.headlineFont.isFallback { measured.fallbackFont = layout.headlineFont.fontName }
        measured.isMirrored = measured.isMirrored || layout.isMirrored
        if !layout.headline.fits || layout.subhead?.fits == false {
            measured.overflows.append(AutopilotOverflow(
                locale: locale.code, slot: slot, displayType: display, headline: caption.headline, subhead: caption.subhead,
                maxLines: layout.headline.maxLines, fill: layout.headline.fill
            ))
        }
    }

    /// The pills on a direction: languages with captions too long (they'll
    /// be shortened), or that everything fits, then a right-to-left
    /// language mirroring and a CJK language fitting.
    func directionChecks(locales: [String]) -> [AutopilotDirectionCheck] {
        var checks: [AutopilotDirectionCheck] = []
        var tooLong: [AutopilotDirectionCheck] = []
        var fitting: Set<String> = []
        for code in locales {
            let result = check(locale: code)
            let lengthy = result.overflows.filter { !$0.headline.isEmpty }.count
            if lengthy > 0 {
                tooLong.append(AutopilotDirectionCheck(kind: .tooLong, locale: code, count: lengthy))
            } else {
                fitting.insert(code)
            }
        }
        if tooLong.isEmpty {
            checks.append(AutopilotDirectionCheck(kind: .fitsAll, locale: nil, count: locales.count))
        } else {
            checks += tooLong.prefix(2)
        }
        if let rtl = locales.first(where: { StoreLocaleCatalog.locale(code: $0)?.isRTL == true }) {
            checks.append(AutopilotDirectionCheck(kind: .mirrors, locale: rtl, count: 0))
        }
        if let cjk = locales.first(where: { ["ja", "zh", "ko"].contains(String($0.prefix(2))) && fitting.contains($0) }) {
            checks.append(AutopilotDirectionCheck(kind: .fits, locale: cjk, count: 0))
        }
        return checks
    }
}
