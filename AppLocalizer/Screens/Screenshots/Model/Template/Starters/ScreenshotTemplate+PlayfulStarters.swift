//
//  ScreenshotTemplate+PlayfulStarters.swift
//  AppLocalizer
//

import Foundation

// The gallery's playful templates: Sparkle, Playful and Highlight.
extension ScreenshotTemplate {
    static func playfulRecipe(_ starter: TemplateStarter) -> ScreenshotTemplate {
        switch starter {
        case .playful: playful
        case .highlight: highlight
        default: sparkle
        }
    }

    private static var sparkle: ScreenshotTemplate {
        let ink = "#2B1166"
        return recipe(
            background: TemplateBackground(kind: .linear, angle: 170, stops: ["#2A1170", "#6B3FD4", "#A985F2"]),
            ink: "#FFFFFF", subInk: "rgba(255,255,255,0.84)", placement: .above, align: .center,
            device: TemplateDevice(show: true, width: 0.78, color: "#121216", offset: 0.06, bleed: 0.1, tilt: TemplateTilt(rotate: -9, turn: 0, lean: 0)),
            headline: TemplateTextStyle(
                font: "Poppins", weight: 500, size: 104, min: 78, lineHeight: 1.1, maxLines: 3, tracking: -0.01,
                emphasis: TemplateEmphasis(line: .last, weight: 800)
            ),
            subhead: TemplateTextStyle(font: "Poppins", weight: 400, size: 46, min: 40, lineHeight: 1.26, maxLines: 2),
            decorations: [
                .shape(.sparkle, x: 0.8, y: 0.25, width: 0.12, color: "#FFFFFF", layer: .front),
                .shape(.sparkle, x: 0.07, y: 0.52, width: 0.07, color: "#FFFFFF", layer: .front),
                .shape(.sparkle, x: 0.84, y: 0.86, width: 0.08, color: "#FFFFFF", layer: .front, opacity: 0.8),
            ],
            slots: [
                slotOverrides(align: .start, tilt: TemplateTilt(rotate: -14, turn: 0, lean: 0), shiftRight: 0.12),
                slotOverrides(tilt: TemplateTilt(rotate: 9, turn: 0, lean: 0)),
                slotOverrides(
                    background: TemplateBackground(kind: .linear, angle: 170, stops: ["#F3EBFF", "#C9B2F7"]), ink: ink, tilt: .flat,
                    decorations: [
                        .shape(.sparkle, x: 0.06, y: 0.03, width: 0.1, color: ink, layer: .front),
                        .shape(.sparkle, x: 0.86, y: 0.2, width: 0.07, color: ink, layer: .front),
                    ]
                ),
                slotOverrides(tilt: TemplateTilt(rotate: 6, turn: 0, lean: 0)),
                [:],
            ]
        )
    }

    private static var playful: ScreenshotTemplate {
        let leaning = TemplateTilt(rotate: 6, turn: 0, lean: 0)
        return recipe(
            background: TemplateBackground(kind: .linear, angle: 165, stops: ["#3C3CF2", "#4A2AC9"]),
            ink: "#FFFFFF", subInk: "rgba(255,255,255,0.86)", placement: .above, align: .center,
            device: TemplateDevice(show: true, width: 0.78, color: "#111114", offset: 0.05, bleed: 0.1, tilt: TemplateTilt(rotate: -6, turn: 0, lean: 0)),
            headline: TemplateTextStyle(
                font: "Lobster", weight: 400, size: 132, min: 94, lineHeight: 1.02, maxLines: 3, tracking: -0.01, shadow: "0 0.05em 0 rgba(18,10,70,0.5)"
            ),
            subhead: TemplateTextStyle(font: "SF Pro Text", weight: 600, size: 46, min: 40, lineHeight: 1.24, maxLines: 2),
            decorations: [.shape(.petal, x: 0.7, y: 0.17, width: 0.5, color: "#FFFFFF", layer: .back)],
            slots: [
                [:],
                slotOverrides(tilt: leaning, decorations: [.shape(.petal, x: -0.22, y: 0.22, width: 0.5, color: "#FFFFFF", layer: .back)]),
                slotOverrides(decorations: [.shape(.blob, x: 0.55, y: 0.24, width: 0.6, color: "#FFFFFF", layer: .back, opacity: 0.95)]),
                slotOverrides(
                    background: TemplateBackground(kind: .solid, stops: ["#F06A45"]), shiftDown: -0.05, width: 0.64,
                    headlineShadow: "0 0.05em 0 rgba(120,30,10,0.45)",
                    decorations: [
                        .shape(.petal, x: 0.72, y: 0.14, width: 0.44, color: "#FFFFFF", layer: .back),
                        .laurel(x: 0.31, y: 0.8, width: 0.38, color: "#FFFFFF", value: "4.5", star: "#FFFFFF"),
                    ]
                ),
                slotOverrides(background: TemplateBackground(kind: .linear, angle: 165, stops: ["#5B2BD8", "#9C4FE0"]), tilt: leaning),
            ]
        )
    }

    private static var highlight: ScreenshotTemplate {
        recipe(
            background: TemplateBackground(kind: .solid, stops: ["#EBDDFF"]),
            ink: "#4B10A8", subInk: "rgba(75,16,168,0.82)", placement: .above, align: .center,
            safe: TemplateSafeArea(top: 0.06, side: 0.08, bottom: 0),
            device: TemplateDevice(show: true, width: 0.74, color: "#9A63F0", offset: 0.04, bleed: 0.1),
            headline: TemplateTextStyle(
                font: "Fredoka", weight: 700, size: 112, min: 82, lineHeight: 1.24, maxLines: 3, tracking: -0.01,
                highlight: TemplateHighlight(color: "#CFAEFF", padding: 0.2, rotation: -2, radius: 0.05, shadow: "0.07em 0.07em 0 #4B10A8")
            ),
            subhead: TemplateTextStyle(font: "Fredoka", weight: 500, size: 50, min: 42, lineHeight: 1.24, maxLines: 2),
            slots: [
                slotOverrides(
                    align: .start, tilt: TemplateTilt(rotate: 18, turn: -10, lean: 20), shiftRight: 0.2,
                    decorations: [.laurel(x: 0.04, y: 0.78, width: 0.38, color: "#6A21D6", value: "4.8", star: "#6A21D6")]
                ),
                [:], slotOverrides(tilt: TemplateTilt(rotate: 0, turn: 14, lean: 4)), [:], slotOverrides(tilt: TemplateTilt(rotate: 0, turn: -14, lean: 4)),
            ]
        )
    }
}
