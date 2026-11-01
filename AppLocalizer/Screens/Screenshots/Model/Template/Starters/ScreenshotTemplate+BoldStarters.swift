//
//  ScreenshotTemplate+BoldStarters.swift
//  AppLocalizer
//

import Foundation

// The gallery's bold templates: Bold Stack, Swoosh and Poster.
extension ScreenshotTemplate {
    static func boldRecipe(_ starter: TemplateStarter) -> ScreenshotTemplate {
        switch starter {
        case .swoosh: swoosh
        case .poster: poster
        default: boldStack
        }
    }

    private static var boldStack: ScreenshotTemplate {
        let angled = TemplateTilt(rotate: -5, turn: 16, lean: 6)
        return recipe(
            background: TemplateBackground(kind: .solid, stops: ["#EFE8DC"]),
            ink: "#2B2547", subInk: "rgba(43,37,71,0.78)", placement: .above, align: .start,
            safe: TemplateSafeArea(top: 0.055, side: 0.075, bottom: 0),
            device: TemplateDevice(show: true, width: 0.72, color: "#1C1C22", offset: 0.05, bleed: 0.1, tilt: TemplateTilt(rotate: 5, turn: -16, lean: 6)),
            headline: TemplateTextStyle(
                font: "Archivo Black", weight: 400, size: 128, min: 88, lineHeight: 1.0, maxLines: 3, tracking: -0.01, uppercase: true,
                emphasis: TemplateEmphasis(line: .first, weight: 500, font: "Archivo")
            ),
            subhead: TemplateTextStyle(font: "SF Pro Text", weight: 500, size: 48, min: 40, lineHeight: 1.24, maxLines: 2),
            decorations: [.shape(.circle, x: 0.2, y: 0.42, width: 0.78, color: "#E4D8C4", layer: .back)],
            slots: [
                slotOverrides(
                    background: TemplateBackground(kind: .solid, stops: ["#2B2648"]), ink: "#F4EEE4", subInk: "rgba(244,238,228,0.82)",
                    tilt: TemplateTilt(rotate: -20, turn: 20, lean: 16), shiftRight: 0.17, shiftDown: 0.02,
                    decorations: [.laurel(x: 0.05, y: 0.775, width: 0.36, color: "#F4EEE4", value: "4.8", star: "#F5C24B")]
                ),
                [:], slotOverrides(tilt: angled), [:], slotOverrides(tilt: angled),
            ]
        )
    }

    private static var swoosh: ScreenshotTemplate {
        let whiteRibbon = TemplateDecoration.shape(.swoosh, x: -0.16, y: 0.27, width: 1.32, height: 0.56, color: "#FFFFFF", layer: .back)
        let greenRibbon = TemplateDecoration.shape(.swoosh, x: -0.16, y: 0.27, width: 1.32, height: 0.56, color: "#5BC85F", layer: .back)
        let white = TemplateBackground(kind: .solid, stops: ["#FFFFFF"])
        return recipe(
            background: TemplateBackground(kind: .solid, stops: ["#5BC85F"]),
            ink: "#FFFFFF", subInk: "rgba(255,255,255,0.88)", placement: .above, align: .center,
            device: TemplateDevice(show: true, width: 0.76, color: "#F3F3F5", offset: 0.05, bleed: 0.1, tilt: TemplateTilt(rotate: 0, turn: -10, lean: 4)),
            headline: TemplateTextStyle(
                font: "Playfair Display", weight: 900, size: 122, min: 86, lineHeight: 1.0, maxLines: 3, tracking: -0.01,
                emphasis: TemplateEmphasis(line: .last, weight: 700, italic: true)
            ),
            subhead: TemplateTextStyle(font: "Playfair Display", weight: 700, size: 52, min: 42, lineHeight: 1.2, maxLines: 2, italic: true),
            decorations: [whiteRibbon],
            slots: [
                slotOverrides(tilt: TemplateTilt(rotate: -8, turn: 0, lean: 0), shiftRight: 0.1),
                slotOverrides(background: white, ink: "#2E8B3A", decorations: [greenRibbon]),
                slotOverrides(
                    tilt: TemplateTilt(rotate: 0, turn: 12, lean: 4),
                    decorations: [whiteRibbon, .badge(x: 0.06, y: 0.78, width: 0.3, color: "#111111", ink: "#FFFFFF", value: "4.8 ★", rotation: -12)]
                ),
                slotOverrides(background: white, ink: "#2E8B3A", decorations: [greenRibbon]),
                [:],
            ]
        )
    }

    private static var poster: ScreenshotTemplate {
        let grey = TemplateBackground(kind: .solid, stops: ["#8E8E93"])
        return recipe(
            background: TemplateBackground(kind: .solid, stops: ["#0F0F10"]),
            ink: "#FFFFFF", subInk: "rgba(255,255,255,0.8)", placement: .above, align: .center,
            safe: TemplateSafeArea(top: 0.05, side: 0.07, bottom: 0),
            device: TemplateDevice(show: true, width: 0.78, color: "#D6D6DB", offset: 0.03, bleed: 0.1),
            headline: TemplateTextStyle(font: "Anton", weight: 400, size: 158, min: 112, lineHeight: 0.98, maxLines: 3, tracking: 0, uppercase: true),
            subhead: TemplateTextStyle(font: "SF Pro Text", weight: 600, size: 46, min: 40, lineHeight: 1.24, maxLines: 2),
            decorations: [.shape(.arc, x: 0.62, y: 0.78, width: 0.44, height: 0.24, color: "#FFFFFF", layer: .back)],
            slots: [
                [:],
                slotOverrides(background: grey, decorations: [.shape(.chevrons, x: 0.72, y: 0.9, width: 0.2, height: 0.065, color: "#FFFFFF", layer: .front)]),
                slotOverrides(decorations: [.shape(.blob, x: 0.66, y: 0.3, width: 0.5, color: "#FFFFFF", layer: .back)]),
                slotOverrides(background: grey, decorations: [.shape(.blob, x: -0.14, y: 0.74, width: 0.42, color: "#FFFFFF", layer: .back)]),
                [:],
            ]
        )
    }
}
