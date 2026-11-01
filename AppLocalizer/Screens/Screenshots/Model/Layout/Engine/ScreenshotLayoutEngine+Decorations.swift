//
//  ScreenshotLayoutEngine+Decorations.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

// Placing the slot's shapes, laurels and badges. `x` and `w` are fractions
// of the canvas width, `y` and `h` of its height, and a decoration without
// a height is square. Right-to-left locales mirror the position and the
// angle and flip shapes, while laurels and badges keep their text readable.
extension ScreenshotLayoutEngine {
    func decorations(context: Context, fontName: String) -> [LayoutDecoration] {
        let width = context.canvas.width
        let height = context.canvas.height
        return (context.template.decorations ?? []).map { decoration in
            let frameWidth = CGFloat(decoration.width) * width
            let frameHeight = decoration.height.map { CGFloat($0) * height } ?? frameWidth
            var x = CGFloat(decoration.x) * width
            if context.isMirrored { x = width - x - frameWidth }
            let frame = CGRect(x: x, y: CGFloat(decoration.y) * height, width: frameWidth, height: frameHeight)
            let color = TemplateColor(decoration.color) ?? .white
            var result = LayoutDecoration(
                kind: decoration.type, shape: decoration.shape, frame: frame,
                rotation: (decoration.rotation ?? 0) * (context.isMirrored ? -1 : 1),
                isFlipped: context.isMirrored && decoration.type == .shape, opacity: decoration.opacity ?? 1, color: color,
                isFront: decoration.layer == .front, text: nil, textColor: color, fontName: fontName, textSize: 0, textWeight: 700,
                starColor: nil, starSize: 0, starGap: 0
            )
            switch decoration.type {
            case .shape:
                break
            case .badge:
                result.text = decoration.value
                result.textColor = decoration.ink.flatMap(TemplateColor.init) ?? .white
                result.textSize = frameWidth * 0.2
                result.textWeight = 800
            case .laurel:
                let side = min(frameWidth, frameHeight)
                result.text = decoration.value
                result.textColor = decoration.ink.flatMap(TemplateColor.init) ?? color
                result.textSize = side * 0.26
                result.textWeight = 700
                if decoration.stars == true {
                    result.starColor = decoration.star.flatMap(TemplateColor.init) ?? color
                    result.starSize = side * 0.075
                    result.starGap = side * 0.03
                }
            }
            return result
        }
    }
}
