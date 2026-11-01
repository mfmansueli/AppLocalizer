//
//  ScreenshotTemplate+ElegantStarters.swift
//  AppLocalizer
//

import Foundation

// The gallery's elegant templates: Cinema, Spotlight and Editorial.
extension ScreenshotTemplate {
    static func elegantRecipe(_ starter: TemplateStarter) -> ScreenshotTemplate {
        switch starter {
        case .spotlight: spotlight
        case .editorial: editorial
        default: cinema
        }
    }

    private static var cinema: ScreenshotTemplate {
        let mirrored = TemplateTilt(rotate: 8, turn: -18, lean: 12)
        return recipe(
            background: TemplateBackground(kind: .linear, angle: 180, stops: ["#B85A4B", "#4A1D18", "#0E0807"]),
            ink: "#FFFFFF", subInk: "rgba(255,255,255,0.8)", placement: .below, align: .center,
            safe: TemplateSafeArea(top: 0.06, side: 0.07, bottom: 0.07),
            device: TemplateDevice(show: true, width: 0.84, color: "#26262A", offset: 0.05, bleed: 0, tilt: TemplateTilt(rotate: -9, turn: 18, lean: 12)),
            headline: TemplateTextStyle(
                font: "Playfair Display", weight: 700, size: 118, min: 84, lineHeight: 1.04, maxLines: 3, tracking: -0.01,
                emphasis: TemplateEmphasis(line: .last, weight: 900)
            ),
            subhead: TemplateTextStyle(font: "SF Pro Text", weight: 500, size: 46, min: 40, lineHeight: 1.26, maxLines: 2),
            slots: [
                [:],
                slotOverrides(
                    shiftDown: 0.07, width: 0.64,
                    decorations: [.laurel(x: 0.3, y: 0.025, width: 0.4, color: "#FFFFFF", value: "4.9", star: "#FFFFFF")]
                ),
                slotOverrides(tilt: mirrored), [:], slotOverrides(tilt: mirrored),
            ]
        )
    }

    private static var spotlight: ScreenshotTemplate {
        recipe(
            background: TemplateBackground(kind: .linear, angle: 180, stops: ["#E255D3", "#8A1F93", "#1A061F"]),
            ink: "#FFFFFF", subInk: "rgba(255,255,255,0.84)", placement: .above, align: .center,
            safe: TemplateSafeArea(top: 0.045, side: 0.06, bottom: 0),
            device: TemplateDevice(
                show: true, width: 0.82, color: "#E7A6EA", offset: 0.03, bleed: 0.1, tilt: TemplateTilt(rotate: -16, turn: 10, lean: 34), shiftDown: -0.02
            ),
            headline: TemplateTextStyle(font: "Playfair Display", weight: 800, size: 128, min: 90, lineHeight: 1.0, maxLines: 3, tracking: -0.01),
            subhead: TemplateTextStyle(font: "Playfair Display", weight: 600, size: 52, min: 42, lineHeight: 1.2, maxLines: 2),
            slots: [
                [:],
                slotOverrides(tilt: TemplateTilt(rotate: 16, turn: -10, lean: 34)),
                [:],
                slotOverrides(
                    tilt: TemplateTilt(rotate: 12, turn: -8, lean: 30), shiftDown: -0.07, width: 0.7,
                    decorations: [.laurel(x: 0.3, y: 0.78, width: 0.4, color: "#FFFFFF", value: "4.8", star: "#FFD25E")]
                ),
                slotOverrides(tilt: TemplateTilt(rotate: 0, turn: -14, lean: 8)),
            ]
        )
    }

    private static var editorial: ScreenshotTemplate {
        let mirrored = TemplateTilt(rotate: -4, turn: 16, lean: 4)
        return recipe(
            background: TemplateBackground(kind: .solid, stops: ["#B9A6CC"]),
            ink: "#1F1A36", subInk: "rgba(31,26,54,0.8)", placement: .above, align: .start,
            device: TemplateDevice(show: true, width: 0.74, color: "#1A1A1F", offset: 0.08, bleed: 0.1, tilt: TemplateTilt(rotate: 4, turn: -16, lean: 4)),
            headline: TemplateTextStyle(
                font: "Poppins", weight: 800, size: 108, min: 80, lineHeight: 1.06, maxLines: 3, tracking: -0.01,
                emphasis: TemplateEmphasis(line: .first, weight: 400)
            ),
            subhead: TemplateTextStyle(font: "Poppins", weight: 400, size: 46, min: 40, lineHeight: 1.26, maxLines: 2),
            slots: [
                slotOverrides(background: TemplateBackground(kind: .solid, stops: ["#2F2B52"]), ink: "#FFFFFF", subInk: "rgba(255,255,255,0.82)"),
                slotOverrides(decorations: [.shape(.sparkle, x: 0.84, y: 0.36, width: 0.08, color: "#F2B33D", layer: .front)]),
                slotOverrides(background: TemplateBackground(kind: .solid, stops: ["#E8E6EC"]), tilt: mirrored),
                slotOverrides(decorations: [.shape(.sparkle, x: 0.08, y: 0.5, width: 0.07, color: "#F2B33D", layer: .front)]),
                slotOverrides(tilt: mirrored),
            ]
        )
    }
}
