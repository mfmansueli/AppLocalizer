//
//  ScreenshotTemplate+Starters.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotTemplate {
    /// A complete template from a starter, as version `version`. `title`
    /// names it, e.g. "Lumen" → "Lumen · Caption above device". Slot 1 is
    /// the hero; there are `slotCount` slots (5 unless the app has more).
    static func starter(_ starter: TemplateStarter, id: String, title: String, version: Int = 1, slotCount: Int = 5) -> ScreenshotTemplate {
        let count = min(max(slotCount, 1), maximumSlots)
        let slots = (0..<count).map { TemplateSlot(layout: $0 == 0 ? .hero : .standard) }
        var template = switch starter {
        case .above: above
        case .band: band
        case .panorama: panorama
        }
        template.id = id
        template.name = "\(title) · \(starter.title)"
        template.version = version
        template.starter = starter
        template.slots = slots
        return template
    }

    private static var above: ScreenshotTemplate {
        ScreenshotTemplate(
            id: "", name: "", version: 1,
            canvas: TemplateCanvas(iphone: .portrait, ipad: .landscape),
            background: TemplateBackground(kind: .linear, angle: 168, stops: ["#7A80FF", "#3A2FB8"]),
            device: TemplateDevice(show: true, width: 0.8, color: "#141416", offset: 0, bleed: 0.07),
            caption: TemplateCaption(
                placement: .above, align: .center, gap: 0.028, ink: "#FFFFFF", subInk: "rgba(255,255,255,0.84)", band: defaultBand,
                headline: TemplateTextStyle(font: "SF Pro Display", weight: 700, size: 112, min: 80, lineHeight: 1.08, maxLines: 2, tracking: -0.01),
                subhead: TemplateTextStyle(font: "SF Pro Text", weight: 500, size: 50, min: 42, lineHeight: 1.24, maxLines: 2)
            ),
            fit: TemplateFit(shrink: true, hyphenate: false), rightToLeft: TemplateRightToLeft(mirror: true),
            safeArea: TemplateSafeArea(top: 0.06, side: 0.075, bottom: 0),
            fonts: TemplateFonts(display: "SF Pro Display", fallback: TemplateFonts.systemFallbacks), slots: []
        )
    }

    private static var band: ScreenshotTemplate {
        var template = above
        template.background = TemplateBackground(kind: .solid, stops: ["#17143D"])
        template.device = TemplateDevice(show: false, width: 1, color: "#141416", offset: 0, bleed: 0)
        template.caption = TemplateCaption(
            placement: .band, align: .center, gap: 0.028, ink: "#FFFFFF", subInk: "rgba(255,255,255,0.8)", band: defaultBand,
            headline: TemplateTextStyle(font: "SF Pro Display", weight: 700, size: 96, min: 72, lineHeight: 1.08, maxLines: 2, tracking: -0.01),
            subhead: TemplateTextStyle(font: "SF Pro Text", weight: 500, size: 46, min: 40, lineHeight: 1.24, maxLines: 2)
        )
        return template
    }

    private static var panorama: ScreenshotTemplate {
        var template = above
        template.background = TemplateBackground(kind: .panorama, stops: ["#FFD8C4", "#F6D3EC", "#DCDDFF", "#C8E5FF", "#D6F1E6"])
        template.device = TemplateDevice(show: true, width: 0.74, color: "#141416", offset: 0.075, bleed: 0.08)
        template.caption = TemplateCaption(
            placement: .above, align: .start, gap: 0.028, ink: "#221E4D", subInk: "rgba(34,30,77,0.74)", band: defaultBand,
            headline: TemplateTextStyle(font: "New York", weight: 700, size: 108, min: 78, lineHeight: 1.06, maxLines: 2, tracking: -0.01),
            subhead: TemplateTextStyle(font: "SF Pro Text", weight: 500, size: 48, min: 40, lineHeight: 1.24, maxLines: 2)
        )
        template.fonts.display = "New York"
        return template
    }

    /// The band every starter keeps for switching to a band placement.
    private static let defaultBand = TemplateBand(color: "#17143D", pos: .bottom)
}
