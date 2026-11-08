//
//  DecorationArtTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import SwiftUI
import Testing
@testable import AppLocalizer

/// The ten props from the design: each drawn from its parts, the marks in
/// the decoration's color and the multi-color ones in their own, fitted
/// whole into the frame or stretched to it.
@Suite("DecorationArt")
struct DecorationArtTests {
    @Test(arguments: TemplateArt.allCases)
    func everyPropHasADrawing(_ art: TemplateArt) {
        let drawing = DecorationArt.drawing(for: art)
        #expect(!drawing.parts.isEmpty, "\(art)")
        #expect(drawing.parts.allSatisfy { !$0.path.isEmpty }, "\(art)")
        #expect(drawing.viewBox.width > 0)
        #expect(drawing.viewBox.height > 0)
    }

    @Test(arguments: TemplateArt.allCases)
    func marksTakeTheColorAndMultiColorPropsKeepTheirOwn(_ art: TemplateArt) {
        let paints = DecorationArt.drawing(for: art).parts.flatMap { [$0.fill, $0.stroke].compactMap(\.self) }
        let usesTint = paints.contains(.tint)
        let hasOwnColors = paints.contains { if case .color = $0 { true } else { false } }
        if art.isTintable {
            #expect(usesTint, "\(art)")
        } else {
            #expect(hasOwnColors, "\(art)")
        }
    }

    @Test func aPartsOwnColorFallsBackToTheTint() {
        #expect(DecorationArtPart.Paint.tint.color(tint: .white) == .white)
        #expect(DecorationArtPart.Paint.color("#000000").color(tint: .white) == .black)
        #expect(DecorationArtPart.Paint.color("not a color").color(tint: .white) == .white)
    }

    @Test func aFittedDrawingIsCenteredWhole() {
        let drawing = DecorationArt(viewBox: CGRect(x: 0, y: 0, width: 100, height: 50), stretches: false, parts: [])
        let frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        let fitted = CGRect(x: 0, y: 0, width: 100, height: 50).applying(drawing.transform(into: frame))
        #expect(fitted == CGRect(x: 0, y: 50, width: 200, height: 100))
    }

    @Test func aStretchedDrawingFillsTheFrame() {
        let drawing = DecorationArt(viewBox: CGRect(x: 10, y: 10, width: 100, height: 50), stretches: true, parts: [])
        let frame = CGRect(x: 20, y: 30, width: 200, height: 200)
        let stretched = CGRect(x: 10, y: 10, width: 100, height: 50).applying(drawing.transform(into: frame))
        #expect(stretched == frame)
    }
}
