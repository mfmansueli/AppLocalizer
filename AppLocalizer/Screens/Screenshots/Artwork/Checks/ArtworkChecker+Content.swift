//
//  ArtworkChecker+Content.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

extension ArtworkChecker {
    /// What Apple doesn't allow, in the text layers and in the text read
    /// from the render. Each finding counts once, wherever it was found.
    func contentChecks(_ input: ArtworkCheckInput, read: [ArtworkReadText]?) -> [ArtworkCheck] {
        var seen: Set<String> = []
        var checks: [ArtworkCheck] = []
        let layers = [input.line] + input.geometry.textLayers
        for text in layers {
            for match in ArtworkForbiddenText.matches(in: text) where seen.insert(match.key).inserted {
                checks.append(ArtworkCheck(kind: match.kind, text: String(localized: "\(input.place): ‘\(match.snippet)’ — \(match.kind.notAllowed).")))
            }
        }
        for line in read ?? [] {
            let center = CGPoint(x: line.frame.midX, y: line.frame.midY)
            let isInterface = input.geometry.interfaceFrames.contains { $0.contains(center) }
            for match in ArtworkForbiddenText.matches(in: line.text) where seen.insert(match.key).inserted {
                if isInterface {
                    checks.append(ArtworkCheck(
                        kind: match.kind, severity: .warning,
                        text: String(localized: "\(input.place), on the phone’s screen: ‘\(match.snippet)’ — \(match.kind.notAllowed). It’s the app’s own interface: check it’s right for this placement.")
                    ))
                } else {
                    checks.append(ArtworkCheck(kind: match.kind, text: String(localized: "\(input.place): ‘\(match.snippet)’ — \(match.kind.notAllowed).")))
                }
            }
        }
        return checks
    }

    /// Apple takes no alpha channel or transparency here: the PNG's header,
    /// else the render's own channel and pixels.
    func transparencyChecks(_ input: ArtworkCheckInput, pixels: ArtworkPixels?) -> [ArtworkCheck] {
        let pngHasAlpha = input.pngData.map(ScreenshotPNG.hasAlpha) ?? false
        let imageHasAlpha = input.image.map(ArtworkPixels.hasAlphaChannel) ?? false
        guard pngHasAlpha || imageHasAlpha else { return [] }
        let text = if pixels?.hasTransparentPixels == true {
            String(localized: "\(input.place): parts of it are see-through — Apple takes no alpha or transparency here.")
        } else {
            String(localized: "\(input.place): the image has an alpha channel — Apple takes no alpha or transparency here.")
        }
        return [ArtworkCheck(kind: .transparency, text: text)]
    }
}
