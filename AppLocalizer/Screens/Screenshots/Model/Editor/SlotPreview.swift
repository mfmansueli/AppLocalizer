//
//  SlotPreview.swift
//  AppLocalizer
//

import Foundation

/// One locale × display type × slot laid out and checked from a given
/// template, for the editors' previews: the template editor's canvas and
/// stress strip, the caption editor's preview and a suggestion's fit. The
/// template may be an unsaved draft, so its render key is its own.
struct SlotPreview: Hashable, Sendable {
    var job: RenderJob
    var checks: [RenderCheck]

    var layout: ScreenshotLayout { job.layout }

    /// The headline's fit: what the meters and labels show.
    var fit: CaptionFit { layout.headline }

    /// The first check that would block the push: overflow, missing
    /// glyphs or a capture of the wrong size.
    var firstFailure: RenderCheck? { ScreenshotChecker.firstFailure(in: checks) }

    /// The caption box drawn red: it overflows or a glyph is missing.
    var hasCaptionProblem: Bool {
        checks.contains { ($0.kind == .fit || $0.kind == .glyphs) && $0.status == .failed }
    }

    /// "Fits at 119 u · 2 lines", "1 line too many at 80 u · 3 lines", or
    /// "No caption".
    var fitLine: String {
        guard !fit.isEmpty else { return String(localized: "No caption") }
        let lines = fit.lines.count == 1 ? String(localized: "1 line") : String(localized: "\(fit.lines.count) lines")
        return "\(fit.label) · \(lines)"
    }

    /// Where a preview goes: a slot of a locale on a display type, laid
    /// out from `template`.
    struct Placement {
        var template: ScreenshotTemplate
        var locale: StoreLocale
        var displayType: ScreenshotDisplayType
        var slot: Int
    }

    /// Lays out and checks one slot. `primaryLocaleName` words the "UI not
    /// localized" warning; laurels and badges are checked against
    /// `ratings`.
    static func make(
        _ placement: Placement,
        caption: ScreenshotCaption?,
        capture: ResolvedCapture?,
        engine: ScreenshotLayoutEngine,
        primaryLocaleName: String,
        ratings: StoreRatings = .unchecked
    ) -> SlotPreview {
        let template = placement.template
        let layout = engine.layout(template, slot: placement.slot, locale: placement.locale, displayType: placement.displayType, caption: caption)
        let key = RenderKey(
            templateHash: template.contentHash, locale: placement.locale.code, displayType: placement.displayType, slot: placement.slot,
            caption: caption, captureID: capture?.capture.id
        )
        let checks = ScreenshotChecker.checks(for: layout, capture: capture, primaryLocaleName: primaryLocaleName, ratings: ratings)
        return SlotPreview(job: RenderJob(key: key, layout: layout, capture: capture?.capture), checks: checks)
    }
}
