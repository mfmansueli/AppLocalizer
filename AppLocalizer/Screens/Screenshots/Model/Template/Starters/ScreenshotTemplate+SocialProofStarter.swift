//
//  ScreenshotTemplate+SocialProofStarter.swift
//  AppLocalizer
//

import Foundation

// Social Proof, a bold template: a light Poppins kicker line over a heavy
// headline on ink, lilac and mist. Big tilted phones bleed off the bottom.
// Slot 1 has the App Store rating on a laurel, slot 2 is real 5-star App
// Store reviews (no device), slot 3 has a moon and sparkles overlapping the
// phone, and on slot 5 a hand holds it.
extension ScreenshotTemplate {
    static var socialProofRecipe: ScreenshotTemplate {
        let lilac = TemplateBackground(kind: .solid, stops: ["#B6A4CB"])
        let gold = "#F5C24B"
        var template = recipe(
            background: TemplateBackground(kind: .solid, stops: ["#E9E7EC"]),
            ink: "#2A2340", subInk: "rgba(42,35,64,0.82)", placement: .above, align: .start,
            safe: TemplateSafeArea(top: 0.042, side: 0.07, bottom: 0),
            device: TemplateDevice(show: true, width: 0.8, color: "#1C1C22", offset: 0, bleed: 0.3),
            headline: TemplateTextStyle(font: "Poppins", weight: 700, size: 128, min: 90, lineHeight: 1.02, maxLines: 3, tracking: -0.025),
            subhead: TemplateTextStyle(font: "Poppins", weight: 400, size: 64, min: 50, lineHeight: 1.18, maxLines: 2),
            slots: [
                slotOverrides(
                    background: TemplateBackground(kind: .solid, stops: ["#2A2340"]), ink: "#FFFFFF", subInk: "rgba(255,255,255,0.9)",
                    tilt: TemplateTilt(rotate: -16, turn: 12, lean: 10), shiftRight: 0.2, shiftDown: 0.03,
                    decorations: [.laurel(x: 0.03, y: 0.79, width: 0.36, color: "#C9BCD9", value: "4.8", star: gold)]
                ),
                slotOverrides(background: lilac),
                slotOverrides(
                    shiftRight: 0.1, width: 0.72,
                    decorations: [
                        .shape(.moon, x: -0.12, y: 0.55, width: 0.62, color: "#B6A4CB", layer: .front),
                        .shape(.sparkle, x: 0.38, y: 0.56, width: 0.12, color: gold, layer: .front),
                        .shape(.sparkle, x: 0.04, y: 0.5, width: 0.07, color: gold, layer: .front),
                    ]
                ),
                slotOverrides(background: lilac, tilt: TemplateTilt(rotate: 6, turn: -22, lean: 10), shiftRight: 0.2, shiftDown: 0.02),
                slotOverrides(
                    tilt: TemplateTilt(rotate: -18, turn: 8, lean: 6), shiftRight: 0.06, shiftDown: 0.05, width: 0.7,
                    decorations: [
                        .shape(.palm, x: 0.3, y: 0.62, width: 0.76, height: 0.42, color: "#E2B593", layer: .back),
                        .shape(.fingers, x: 0.8, y: 0.55, width: 0.24, height: 0.2, color: "#D9A984", layer: .front, rotation: -16),
                    ]
                ),
            ]
        )
        template.caption.kicker = TemplateTextStyle(font: "Poppins", weight: 400, size: 86, min: 62, lineHeight: 1.15, maxLines: 1)
        template.slots[1].layout = .quotes
        return template
    }
}
