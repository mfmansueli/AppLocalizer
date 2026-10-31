//
//  IconPaletteTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The colors AppLocalizer's starters take from the app icon.
@MainActor
@Suite("Icon palette")
struct IconPaletteTests {
    private static let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

    private static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1) -> CGColor {
        CGColor(colorSpace: srgb, components: [red, green, blue, alpha]) ?? CGColor(gray: 0, alpha: alpha)
    }

    @Test func aSymbolIconsGradientIsThePalette() async {
        let palette = await IconPalette.palette(for: .symbol("moon.fill", top: 0x7C86FF, bottom: 0x3A2FB8))
        #expect(palette == IconPalette(light: "#7C86FF", dark: "#3A2FB8"))
        #expect(await IconPalette.palette(for: nil) == nil)
    }

    @Test func anImagesTopAndBottomThirdsAreItsEnds() throws {
        let image = try #require(AutopilotTestFixtures.twoBandImage(top: Self.color(1, 0, 0), bottom: Self.color(0, 0, 1)))
        #expect(IconPalette.palette(of: image) == IconPalette(light: "#FF0000", dark: "#0000FF"))
    }

    @Test func aTransparentImageHasNoPalette() throws {
        let clear = Self.color(1, 1, 1, alpha: 0)
        let image = try #require(AutopilotTestFixtures.twoBandImage(top: clear, bottom: clear))
        #expect(IconPalette.palette(of: image) == nil)
    }

    @Test func shadesMixTowardsBlackAndWhite() {
        let palette = IconPalette(light: "#FFFFFF", dark: "#000000")
        #expect(palette.darkest == "#000000")
        #expect(palette.gradient == ["#EBEBEB", "#000000"])
        #expect(palette.panorama == ["#FFFFFF", "#D1D1D1", "#FFFFFF", "#BDBDBD", "#FFFFFF"])

        let indigo = IconPalette(light: "#7C86FF", dark: "#3A2FB8")
        #expect(indigo.darkest == "#201A65")
        #expect(IconPalette(light: "nonsense", dark: "#12").darkest == "#000000", "Unreadable colors count as black")
    }
}
#endif
