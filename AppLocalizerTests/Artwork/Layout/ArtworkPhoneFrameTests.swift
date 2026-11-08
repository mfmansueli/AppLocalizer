//
//  ArtworkPhoneFrameTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The search and wide artwork's phones wear the screenshots' 3D
/// iPhone frame (`DeviceFramePainter`): the template's finish, the bezel
/// around the screen, the Dynamic Island, the shadow; bare, no frame.
@MainActor
@Suite("Artwork phone frame")
struct ArtworkPhoneFrameTests {
    @Test func aPhoneIsTheScreenshotsIPhone() throws {
        var template = ArtworkCheckFixtures.template()
        template.device.color = "#C9C2B8"
        let layout = ArtworkCheckFixtures.layout(.search, headline: "Write a little every day", template: template)
        let phone = try #require(layout.phones.first)
        let device = try #require(phone.device)
        #expect(device.frame == phone.frame)
        #expect(device.color == TemplateColor("#C9C2B8"))
        #expect(abs(device.bezel - (phone.screen.minX - phone.frame.minX)) < 0.001)
        #expect(device.cornerRadius == phone.cornerRadius)
        #expect(device.tilt == nil, "The artwork turns it")
        #expect(!device.isLaptop)
        let island = try #require(device.island, "An iPhone's island")
        #expect(phone.screen.contains(island))
        #expect(abs(island.midX - phone.screen.midX) < 0.5)
    }

    @Test func aBareScreenHasNoFrame() throws {
        let layout = ArtworkCheckFixtures.layout(.search, headline: "Write a little every day", shows: .ui)
        let phone = try #require(layout.phones.first)
        #expect(phone.isBare)
        #expect(phone.device == nil)
    }

    /// The rim's highlights show around the screen: the frame isn't a
    /// flat body any more.
    @Test func theFrameIsDrawnInTheRender() throws {
        var template = ArtworkCheckFixtures.template()
        template.device.color = "#141416"
        let layout = ArtworkCheckFixtures.layout(.search, headline: "Write a little every day", template: template)
        let phone = try #require(layout.phones.first)
        let image = try #require(ArtworkCheckFixtures.render(layout))
        let colors = try Self.rimColors(of: phone, in: image, size: layout.size)
        let brightest = try #require(colors.max())
        #expect(brightest > 0.2, "A lit rim on a near-black finish: \(brightest)")
    }

    /// Brightness along the left edge of the body, between the frame and
    /// the screen, sampled unturned at the phone's middle height.
    private static func rimColors(of phone: ArtworkPhone, in image: CGImage, size: CGSize) throws -> [Double] {
        let scaleX = Double(image.width) / size.width
        let scaleY = Double(image.height) / size.height
        let y = Int(phone.frame.midY * scaleY)
        let fromX = Int(phone.frame.minX * scaleX) + 1
        let toX = max(fromX + 1, Int(phone.screen.minX * scaleX) - 1)
        let data = try #require(image.dataProvider?.data as Data?)
        let bytesPerPixel = image.bitsPerPixel / 8
        return (fromX..<toX).compactMap { x in
            guard x >= 0, x < image.width, y >= 0, y < image.height else { return nil }
            let offset = y * image.bytesPerRow + x * bytesPerPixel
            guard offset + 2 < data.count else { return nil }
            return (Double(data[offset]) + Double(data[offset + 1]) + Double(data[offset + 2])) / (3 * 255)
        }
    }
}
#endif
