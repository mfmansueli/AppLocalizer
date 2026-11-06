//
//  ArtworkPanoramaTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// MB Admin's Panorama header was a bare gradient while its screenshots
/// had the panorama's soft discs and waves: the header, search and 16:9
/// images now draw the same picture.
@MainActor
@Suite("Artwork panorama")
struct ArtworkPanoramaTests {
    private typealias Fixtures = ArtworkCheckFixtures

    private static var panoramaLook: ScreenshotTemplate {
        var template = ScreenshotTemplate.starter(.panorama, id: "mb", title: "MB Admin", slotCount: 6)
        StarterDirectionMaker.color(&template, as: .panorama, with: IconPalette(light: "#EAD9D6", dark: "#B79C9E"))
        return template
    }

    @Test func aPanoramaLookCarriesItsPictureAcross() throws {
        let header = Fixtures.layout(.header, headline: "", template: Self.panoramaLook)
        let panorama = try #require(header.panorama)
        #expect(panorama.slotCount == 5, "Slots of a portrait iPhone's shape at the header's height")
        #expect(panorama.slot == 0)
        #expect(panorama.stops.count == Self.panoramaLook.background.stops.count)
        #expect(header.panoramaSlotSize == CGSize(width: 3840 / 5, height: 1646))
        #expect(Fixtures.layout(.search, headline: "Every shop", template: Self.panoramaLook).panorama?.slotCount == 3)
        #expect(Fixtures.layout(.wide, headline: "", template: Self.panoramaLook).panorama?.slotCount == 4)

        // The checks still measure against its gradient.
        guard case .linear = header.background else {
            Issue.record("A panorama's background is its gradient")
            return
        }
    }

    @Test func otherLooksAndScenesDrawNoPicture() {
        #expect(Fixtures.layout(.header, headline: "").panorama == nil, "A solid look")
        #expect(Fixtures.layout(.search, headline: "Every shop", template: Self.panoramaLook, shows: .scene).panorama == nil)
    }

    @Test func thePictureIsDrawn() throws {
        var plain = Fixtures.layout(.header, headline: "", template: Self.panoramaLook, appName: nil)
        let drawn = try #require(Fixtures.render(plain))
        plain.panorama = nil
        let bare = try #require(Fixtures.render(plain))
        // The first slot's big white disc lightens the top left.
        let point = CGPoint(x: 3840 / 5 * 0.48, y: 1646 * 0.2)
        let withDisc = try #require(Self.gray(drawn, at: point))
        let without = try #require(Self.gray(bare, at: point))
        #expect(withDisc > without + 0.01, "\(withDisc) vs \(without)")
    }

    /// The gray level at a point measured from the top left, 0–1.
    private static func gray(_ image: CGImage, at point: CGPoint) -> Double? {
        let scaleX = CGFloat(image.width) / 3840
        let scaleY = CGFloat(image.height) / 1646
        let x = Int(point.x * scaleX)
        let y = Int(point.y * scaleY)
        guard let crop = image.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)) else { return nil }
        var pixel = [UInt8](repeating: 0, count: 4)
        let drawn = pixel.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return true
        }
        guard drawn else { return nil }
        return (Double(pixel[0]) + Double(pixel[1]) + Double(pixel[2])) / (3 * 255)
    }
}
#endif
