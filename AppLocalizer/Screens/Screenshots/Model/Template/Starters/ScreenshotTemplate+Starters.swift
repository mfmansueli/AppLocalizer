//
//  ScreenshotTemplate+Starters.swift
//  AppLocalizer
//

import Foundation

// Making a template from a gallery starter, and the parts every starter's
// recipe is built from. The recipes themselves are in the style files next
// to this one.
extension ScreenshotTemplate {
    /// A complete template from a starter, as version `version`. `title`
    /// names it, e.g. "Lumen" → "Lumen · Caption above device". Slot 1 is
    /// the hero; there are `slotCount` slots (5 unless the app has more).
    /// Slots past the recipe's five repeat slots 2–5 (Two phones stays Two
    /// phones) without their ratings and figures spanning two slots.
    static func starter(_ starter: TemplateStarter, id: String, title: String, version: Int = 1, slotCount: Int = 5) -> ScreenshotTemplate {
        let count = min(max(slotCount, 1), maximumSlots)
        var template = recipe(for: starter)
        let recipeSlots = template.slots
        template.slots = (0..<count).map { index in
            if recipeSlots.indices.contains(index) { return recipeSlots[index] }
            guard recipeSlots.count > 1 else { return TemplateSlot(layout: index == 0 ? .hero : .standard) }
            let repeated = recipeSlots[1 + (index - 1) % (recipeSlots.count - 1)]
            return TemplateSlot(layout: repeated.layout == .pair ? .pair : .standard, over: withoutRepeatedDecorations(repeated.over))
        }
        template.id = id
        template.name = "\(title) · \(starter.title)"
        template.version = version
        template.starter = starter
        return template
    }

    private static func recipe(for starter: TemplateStarter) -> ScreenshotTemplate {
        switch starter.style {
        case .simple: simpleRecipe(starter)
        case .bold: boldRecipe(starter)
        case .elegant: elegantRecipe(starter)
        case .playful: playfulRecipe(starter)
        }
    }

    // MARK: - Simple

    private static func simpleRecipe(_ starter: TemplateStarter) -> ScreenshotTemplate {
        switch starter {
        case .band: band
        case .panorama: panorama
        default: above
        }
    }

    private static var above: ScreenshotTemplate {
        recipe(
            background: TemplateBackground(kind: .linear, angle: 168, stops: ["#7A80FF", "#3A2FB8"]),
            ink: "#FFFFFF", subInk: "rgba(255,255,255,0.84)", placement: .above, align: .center,
            device: TemplateDevice(show: true, width: 0.8, color: "#141416", offset: 0, bleed: 0.07),
            headline: TemplateTextStyle(font: "SF Pro Display", weight: 700, size: 112, min: 80, lineHeight: 1.08, maxLines: 2, tracking: -0.01),
            subhead: TemplateTextStyle(font: "SF Pro Text", weight: 500, size: 50, min: 42, lineHeight: 1.24, maxLines: 2)
        )
    }

    private static var band: ScreenshotTemplate {
        recipe(
            background: TemplateBackground(kind: .solid, stops: ["#17143D"]),
            ink: "#FFFFFF", subInk: "rgba(255,255,255,0.8)", placement: .band, align: .center,
            device: TemplateDevice(show: false, width: 1, color: "#141416", offset: 0, bleed: 0),
            headline: TemplateTextStyle(font: "SF Pro Display", weight: 700, size: 96, min: 72, lineHeight: 1.08, maxLines: 2, tracking: -0.01),
            subhead: TemplateTextStyle(font: "SF Pro Text", weight: 500, size: 46, min: 40, lineHeight: 1.24, maxLines: 2)
        )
    }

    private static var panorama: ScreenshotTemplate {
        recipe(
            background: TemplateBackground(kind: .panorama, stops: ["#FFD8C4", "#F6D3EC", "#DCDDFF", "#C8E5FF", "#D6F1E6"]),
            ink: "#221E4D", subInk: "rgba(34,30,77,0.74)", placement: .above, align: .start,
            device: TemplateDevice(show: true, width: 0.74, color: "#141416", offset: 0.075, bleed: 0.08),
            headline: TemplateTextStyle(font: "New York", weight: 700, size: 108, min: 78, lineHeight: 1.06, maxLines: 2, tracking: -0.01),
            subhead: TemplateTextStyle(font: "SF Pro Text", weight: 500, size: 48, min: 40, lineHeight: 1.24, maxLines: 2)
        )
    }

    // MARK: - Parts

    /// A starter's template from its parts; the display font is the
    /// headline's. Without slot overrides the recipe leaves the slots to
    /// `starter(_:…)`.
    static func recipe(
        background: TemplateBackground, ink: String, subInk: String, placement: TemplateCaption.Placement = .above,
        align: TemplateCaption.Alignment = .center, safe: TemplateSafeArea = TemplateSafeArea(top: 0.06, side: 0.075, bottom: 0), device: TemplateDevice,
        headline: TemplateTextStyle, subhead: TemplateTextStyle, decorations: [TemplateDecoration]? = nil, slots: [[String: JSONValue]] = []
    ) -> ScreenshotTemplate {
        ScreenshotTemplate(
            id: "", name: "", version: 1,
            canvas: TemplateCanvas(iphone: .portrait, ipad: .landscape),
            background: background, device: device,
            caption: TemplateCaption(
                placement: placement, align: align, gap: 0.028, ink: ink, subInk: subInk, band: defaultBand, headline: headline, subhead: subhead
            ),
            fit: TemplateFit(shrink: true, hyphenate: false), rightToLeft: TemplateRightToLeft(mirror: true),
            safeArea: safe, fonts: TemplateFonts(display: headline.font, fallback: TemplateFonts.systemFallbacks),
            decorations: decorations,
            slots: slots.enumerated().map { TemplateSlot(layout: $0.offset == 0 ? .hero : .standard, over: $0.element) }
        )
    }

    /// One slot's overrides, under the paths README §3 gives them.
    static func slotOverrides(
        background: TemplateBackground? = nil, ink: String? = nil, subInk: String? = nil, align: TemplateCaption.Alignment? = nil,
        tilt: TemplateTilt? = nil, shiftRight: Double? = nil, shiftDown: Double? = nil, width: Double? = nil,
        headlineShadow: String? = nil, decorations: [TemplateDecoration]? = nil
    ) -> [String: JSONValue] {
        var over: [String: JSONValue] = [:]
        if let background { over["bg"] = encoded(background) }
        if let ink { over["caption.ink"] = .string(ink) }
        if let subInk { over["caption.subInk"] = .string(subInk) }
        if let align { over["caption.align"] = .string(align.rawValue) }
        if let tilt { over["device.tilt"] = encoded(tilt) }
        if let shiftRight { over["device.dx"] = .double(shiftRight) }
        if let shiftDown { over["device.dy"] = .double(shiftDown) }
        if let width { over["device.width"] = .double(width) }
        if let headlineShadow { over["caption.headline.shadow"] = .string(headlineShadow) }
        if let decorations { over["deco"] = encoded(decorations) }
        return over
    }

    static func encoded(_ value: some Encodable) -> JSONValue {
        (try? JSONValue(encoding: value)) ?? .null
    }

    /// Landscape overrides as they read back from JSON (a whole number is
    /// an integer there), so a saved template equals the starter.
    static func landscapeOverrides(_ values: [String: JSONValue]) -> [String: JSONValue] {
        values.mapValues { encoded($0) }
    }

    /// A repeated slot keeps its shapes and props but not its laurels and
    /// badges (one rating per set is plenty) or a figure spanning two
    /// slots, whose other half isn't next to it any more.
    private static func withoutRepeatedDecorations(_ over: [String: JSONValue]) -> [String: JSONValue] {
        guard let items = over["deco"]?.arrayValue else { return over }
        var result = over
        result["deco"] = .array(items.filter { item in
            let type = item.objectValue?["type"]?.stringValue
            let isRating = type == TemplateDecoration.Kind.laurel.rawValue || type == TemplateDecoration.Kind.badge.rawValue
            return !isRating && item.objectValue?["span"] == nil
        })
        return result
    }

    /// The band every starter keeps for switching to a band placement.
    private static let defaultBand = TemplateBand(color: "#17143D", pos: .bottom)
}
