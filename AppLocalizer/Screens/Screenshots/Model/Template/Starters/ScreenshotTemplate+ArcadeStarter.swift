//
//  ScreenshotTemplate+ArcadeStarter.swift
//  AppLocalizer
//

import Foundation

// Arcade, a bold template: huge white Boldonse caps on electric blue, big
// straight phones (85% wide, their top pinned at 27%) that run off the
// bottom, hand-drawn marks and props. Slot 3 is Two phones, and one figure
// spans the seam between slots 4 and 5. Empty screens are black, so a set
// without captures still looks like the finished design. Lying down (iPad,
// Mac) the caps are smaller and the device isn't pinned, so it sits under
// three lines of caption.
extension ScreenshotTemplate {
    static var arcadeRecipe: ScreenshotTemplate {
        let white = "#FFFFFF"
        var template = recipe(
            background: TemplateBackground(kind: .linear, angle: 165, stops: ["#4B70FF", "#3F63FB", "#3A5CF2"]),
            ink: white, subInk: "rgba(255,255,255,0.88)", placement: .above, align: .center,
            safe: TemplateSafeArea(top: 0.05, side: 0.05, bottom: 0),
            device: TemplateDevice(show: true, width: 0.85, color: "#A9ACB4", offset: 0, bleed: 0.3, top: 0.267, emptyScreen: .black),
            headline: TemplateTextStyle(
                font: "Boldonse", weight: 400, size: 143, min: 84, lineHeight: 1.5, maxLines: 3, tracking: 0, uppercase: true, tight: true
            ),
            subhead: TemplateTextStyle(font: "SF Pro Text", weight: 600, size: 50, min: 42, lineHeight: 1.24, maxLines: 2),
            slots: [
                ["deco": encoded([
                    TemplateDecoration.art(.controller, x: 0.73, y: 0.19, width: 0.34, height: 0.11, rotation: -20, avoid: .down),
                ])],
                ["deco": encoded([
                    TemplateDecoration.art(.underline, x: 0.12, y: 0.004, width: 0.76, height: 0.042, color: white, anchor: .caption),
                    TemplateDecoration.art(.chess, x: 0.52, y: 0.77, width: 0.52, height: 0.25),
                ])],
                [
                    "device.dx": .double(0.19),
                    "device.top": .double(0.372),
                    "device.pair": encoded(TemplateDevicePair(shiftRight: -0.215, top: 0.249)),
                    "deco": encoded([
                        TemplateDecoration.art(.asterisk, x: 0, y: 0, width: 0.13, height: 0.06, color: white, anchor: .firstLineEnd),
                        TemplateDecoration.art(.arrow, x: 0.78, y: 0.24, width: 0.19, height: 0.115, color: white, avoid: .down),
                    ]),
                ],
                ["deco": encoded([
                    TemplateDecoration.art(.corner, x: 0.865, y: -0.005, width: 0.14, height: 0.27, color: white, layer: .back, avoid: .squeeze),
                    TemplateDecoration.art(.pointer, x: 0.885, y: 0.205, width: 0.085, height: 0.04, color: white, avoid: .down),
                    TemplateDecoration.art(.person, x: 0.6, y: 0.42, width: 0.74, height: 0.6, span: 4),
                ])],
                ["deco": encoded([
                    TemplateDecoration.art(.star, x: 0.75, y: 0.004, width: 0.24, height: 0.125, color: white, layer: .back, avoid: .hide),
                    TemplateDecoration.art(.dice, x: 0.78, y: 0.195, width: 0.27, height: 0.125, rotation: 14, avoid: .down),
                    TemplateDecoration.art(.person, x: -0.4, y: 0.42, width: 0.74, height: 0.6, span: 3),
                ])],
            ]
        )
        // Every slot is standard but the third, which stacks two phones.
        template.slots[0].layout = .standard
        template.slots[2].layout = .pair
        template.landscape = landscapeOverrides([
            "device.top": .null,
            "device.dx": .double(0),
            "device.pair": .object(["dx": .double(-0.2), "top": .null]),
            "caption.headline.size": .double(92),
            "caption.headline.min": .double(64),
            "caption.headline.maxLines": .int(3),
        ])
        return template
    }
}
