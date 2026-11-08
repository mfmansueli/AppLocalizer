//
//  StressStripPlanner.swift
//  AppLocalizer
//

import Foundation

/// Picks and lays out the stress strip for one slot (design README §2,
/// §10): the primary locale; the longer of German and Finnish on this
/// slot, measured with the template; Arabic; Japanese. A stress locale
/// without a caption is previewed with a translation of the primary
/// caption, or with the primary caption itself until that arrives. Pure;
/// the template editor runs it on every edit.
struct StressStripPlanner {
    var engine: ScreenshotLayoutEngine

    /// The locales "Longest" is measured among.
    static let longestCandidates = ["de-DE", "fi"]
    static let rightToLeftLocale = "ar-SA"
    static let cjkLocale = "ja"

    /// What the strip needs from the document for one locale.
    struct Inputs {
        var template: ScreenshotTemplate
        var slot: Int
        var displayType: ScreenshotDisplayType
        var primary: StoreLocale
        /// The locale's own caption on the slot.
        var ownCaption: (String) -> ScreenshotCaption?
        /// A preview translation of the primary caption, if one arrived.
        var previewCaption: (String) -> ScreenshotCaption?
        /// The capture the locale's render uses.
        var capture: (String) -> ResolvedCapture?
        /// The capture a Two phones slot shows behind, for the locale.
        var behind: (String) -> ScreenshotCapture? = { _ in nil }
    }

    func entries(_ inputs: Inputs) -> [StressStripEntry] {
        let primary = entry(for: inputs.primary, role: .primary, inputs: inputs)
        // Ties go to the first candidate, German.
        let longest = Self.longestCandidates
            .filter { $0 != inputs.primary.code }
            .compactMap(StoreLocaleCatalog.locale(code:))
            .map { entry(for: $0, role: .longest, inputs: inputs) }
            .reduce(nil) { (best: StressStripEntry?, next: StressStripEntry) in
                guard let best else { return next }
                return measuredFill(next) > measuredFill(best) ? next : best
            }
        let others: [StressStripEntry] = [(Self.rightToLeftLocale, StressStripEntry.Role.rightToLeft), (Self.cjkLocale, .cjk)]
            .filter { $0.0 != inputs.primary.code }
            .compactMap { code, role in StoreLocaleCatalog.locale(code: code).map { entry(for: $0, role: role, inputs: inputs) } }
        return [primary] + (longest.map { [$0] } ?? []) + others
    }

    /// How long a candidate runs: its fill, with a stand-in counting as
    /// shorter than a real caption or preview.
    private func measuredFill(_ entry: StressStripEntry) -> Double {
        entry.captionSource == .primaryStandIn || entry.captionSource == .none ? -1 : entry.preview.fit.fill
    }

    private func entry(for locale: StoreLocale, role: StressStripEntry.Role, inputs: Inputs) -> StressStripEntry {
        let code = locale.code
        var caption = inputs.ownCaption(code)
        var source = StressStripEntry.CaptionSource.own
        if caption == nil, code != inputs.primary.code {
            if let preview = inputs.previewCaption(code) {
                caption = preview
                source = .previewTranslation
            } else if let primary = inputs.ownCaption(inputs.primary.code) {
                caption = primary
                source = .primaryStandIn
            }
        }
        if caption == nil { source = .none }
        let preview = SlotPreview.make(
            SlotPreview.Placement(template: inputs.template, locale: locale, displayType: inputs.displayType, slot: inputs.slot),
            caption: caption, capture: inputs.capture(code), behind: inputs.behind(code), engine: engine, primaryLocaleName: inputs.primary.name
        )
        return StressStripEntry(locale: locale, role: role, caption: caption, captionSource: source, preview: preview)
    }
}
