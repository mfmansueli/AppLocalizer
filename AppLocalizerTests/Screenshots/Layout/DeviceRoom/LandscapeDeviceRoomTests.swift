//
//  LandscapeDeviceRoomTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// On a Mac canvas a tilted MacBook (its raised and lowered corners and
/// its base) fits between the caption and the canvas's edge in every
/// template and slot, even under German's longest headline. On the Mac
/// and a landscape iPad, a laurel or badge that would sit on the device
/// stands beside it instead, under it, or the device moves aside.
@MainActor
@Suite("Landscape device room")
struct LandscapeDeviceRoomTests {
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)
    private static let macBook = PixelSize(width: 2880, height: 1800)
    private static let captions: [StoreLocale: ScreenshotCaption] = [
        .englishUS: ScreenshotCaption(headline: "Keep the photos that matter", subhead: "Gentle prompts that fit your mood"),
        .german: ScreenshotCaption(
            headline: "Durchsuche jahrelange Tagebucheinträge in nur wenigen Sekunden", subhead: "Sanfte Fragen, passend zu deiner Stimmung"
        ),
    ]

    @Test(arguments: TemplateStarter.allCases)
    func aTiltedMacBookStaysClearOfTheCaptionAndOnTheCanvas(_ starter: TemplateStarter) throws {
        let template = ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
        guard template.device.show else { return }
        for slot in template.slots.indices where !template.isQuotes(slot: slot) {
            for (locale, caption) in Self.captions {
                let result = engine.layout(
                    template, slot: slot, locale: locale, displayType: .mac, caption: caption, captureSize: Self.macBook
                )
                let device = try #require(result.device, "\(starter) slot \(slot + 1)")
                let tilt = template.resolved(forSlot: slot, isLandscape: true).device.tilt ?? .flat
                let lift = LayoutTilt.lift(for: tilt, size: device.frame.size)
                let top = device.frame.minY - lift
                let bottom = (device.base ?? device.frame).maxY + lift
                let label = "\(starter) slot \(slot + 1) \(locale.code)"
                if result.captionBox.midY < device.frame.midY {
                    #expect(top >= result.captionBox.maxY - 1, "\(label): the raised corner stays under the caption")
                } else {
                    #expect(bottom <= result.captionBox.minY + 1, "\(label): the base stays over the caption")
                }
                #expect(top >= -1, "\(label): the top stays on the canvas")
                #expect(bottom <= result.canvas.height + 1, "\(label): the base stays on the canvas")
            }
        }
    }

    @Test func cinemasLaurelStandsBesideTheMacBook() throws {
        let cinema = ScreenshotTemplate.starter(.cinema, id: "lumen", title: "Lumen")
        let slot = try #require(cinema.slots.indices.first { cinema.resolved(forSlot: $0).decorations?.contains(where: \.isRating) == true })
        let result = engine.layout(
            cinema, slot: slot, locale: .englishUS, displayType: .mac, caption: Self.captions[.englishUS], captureSize: Self.macBook
        )
        let device = try #require(result.device)
        let laurel = try #require(result.decorations.first { $0.kind == .laurel })
        let body = device.frame.union(device.base ?? device.frame)
        #expect(!laurel.frame.intersects(body), "The laurel isn't drawn on the MacBook")
        let portraitWidth = 0.4 * result.canvas.height
        #expect(laurel.frame.width >= portraitWidth * ScreenshotLayoutEngine.smallestBesideDevice - 1)
        #expect(laurel.frame.minX >= 0 && laurel.frame.maxX <= result.canvas.width)
    }

    @Test(arguments: TemplateStarter.allCases)
    func aLaurelKeepsOffTheLandscapeDeviceAndTheEdges(_ starter: TemplateStarter) {
        let template = ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
        let iPad = PixelSize(width: 2732, height: 2048)
        for display in [ScreenshotDisplayType.mac, .iPad] {
            for slot in template.slots.indices {
                for (locale, caption) in Self.captions.sorted(by: { $0.key.code < $1.key.code }) + [(.arabic, Self.captions[.englishUS])] {
                    let result = engine.layout(
                        template, slot: slot, locale: locale, displayType: display, caption: caption,
                        captureSize: display == .mac ? Self.macBook : iPad
                    )
                    guard result.canvas.isLandscape else { continue }
                    expectRatingsClear(of: result, label: "\(starter) \(display.shortTitle) slot \(slot + 1) \(locale.code)")
                }
            }
        }
    }

    @Test func spotlightsIPadMovesAsideForItsLaurel() throws {
        let spotlight = ScreenshotTemplate.starter(.spotlight, id: "lumen", title: "Lumen")
        let slot = try #require(spotlight.slots.indices.first { spotlight.resolved(forSlot: $0).decorations?.contains(where: \.isRating) == true })
        let result = engine.layout(
            spotlight, slot: slot, locale: .englishUS, displayType: .iPad, caption: Self.captions[.englishUS],
            captureSize: PixelSize(width: 2732, height: 2048)
        )
        #expect(result.canvas.isLandscape)
        let laurel = try #require(result.decorations.first { $0.kind == .laurel }, "The laurel stays")
        let device = try #require(result.device)
        #expect(!laurel.frame.intersects(device.frame), "The laurel isn't drawn on the iPad")
    }

    private func expectRatingsClear(of result: ScreenshotLayout, label: String) {
        let margin = 0.02 * result.canvas.width - 1
        for rating in result.decorations where rating.kind == .laurel || rating.kind == .badge {
            #expect(rating.frame.minX >= margin && rating.frame.maxX <= result.canvas.width - margin, "\(label): on the canvas")
            if let device = result.device {
                let body = device.frame.union(device.base ?? device.frame)
                #expect(!rating.frame.intersects(body), "\(label): not on the device")
            }
        }
    }

    @Test func aFlatMacBookKeepsItsSize() throws {
        // Arcade's MacBook stands straight: no corners to make room for.
        let arcade = ScreenshotTemplate.starter(.arcade, id: "lumen", title: "Lumen")
        let result = engine.layout(
            arcade, slot: 0, locale: .englishUS, displayType: .mac,
            caption: ScreenshotCaption(headline: "Write it down"), captureSize: Self.macBook
        )
        let device = try #require(result.device)
        let canvas = result.canvas
        let bezel = ScreenshotLayoutEngine.deviceShape(for: .mac).bezel
        let width = CGFloat(arcade.device.width) * canvas.width * ScreenshotLayoutEngine.laptopWidth
        let byWidth = width * (1 - 2 * bezel) * (canvas.height / canvas.width) + 2 * bezel * width
        let byRoom = 0.9 * canvas.height - result.captionBox.maxY - CGFloat(arcade.caption.gap) * canvas.height
        let expected = min(byWidth, byRoom)
        #expect(abs(device.frame.height - expected) < 2, "Sized as before: \(device.frame.height) vs \(expected)")
    }
}
