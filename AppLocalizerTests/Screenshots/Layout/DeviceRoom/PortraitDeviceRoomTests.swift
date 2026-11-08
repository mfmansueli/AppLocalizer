//
//  PortraitDeviceRoomTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// On portrait canvases wider than an iPhone's (iPhone Duo's inner
/// display, a portrait iPad), a laurel or badge is never mostly hidden by
/// the device: the device stands under or over it, as on iPhone, where a
/// corner of the phone may overlap it by design.
@MainActor
@Suite("Portrait device room")
struct PortraitDeviceRoomTests {
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)
    private static let duo = PixelSize(width: 2007, height: 2853)
    private static let iPadPortrait = PixelSize(width: 2048, height: 2732)
    private static let caption = ScreenshotCaption(headline: "Keep the photos that matter", subhead: "Gentle prompts that fit your mood")

    @Test(arguments: TemplateStarter.allCases)
    func noLaurelIsMostlyHiddenByTheDevice(_ starter: TemplateStarter) {
        var template = ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
        template.canvas.setOrientation(.portrait, for: .iPad)
        for (display, size) in [(ScreenshotDisplayType.iPhoneDuo, Self.duo), (.iPad, Self.iPadPortrait)] {
            for slot in template.slots.indices {
                for locale in [StoreLocale.englishUS, .arabic] {
                    let result = engine.layout(template, slot: slot, locale: locale, displayType: display, caption: Self.caption, captureSize: size)
                    guard !result.canvas.isLandscape, let device = result.device else { continue }
                    let body = device.frame.union(device.base ?? device.frame)
                    for rating in result.decorations where rating.kind == .laurel || rating.kind == .badge {
                        let covered = rating.frame.intersection(body)
                        let share = covered.isNull ? 0 : covered.width * covered.height / (rating.frame.width * rating.frame.height)
                        #expect(
                            share <= ScreenshotLayoutEngine.coveredRatingShare + 0.01,
                            "\(starter) \(display.shortTitle) slot \(slot + 1) \(locale.code): \(Int(share * 100))% covered"
                        )
                    }
                }
            }
        }
    }

    @Test func cinemasDuoStandsUnderItsLaurel() throws {
        let cinema = ScreenshotTemplate.starter(.cinema, id: "lumen", title: "Lumen")
        let slot = try #require(cinema.slots.indices.first { cinema.resolved(forSlot: $0).decorations?.contains(where: \.isRating) == true })
        let result = engine.layout(cinema, slot: slot, locale: .englishUS, displayType: .iPhoneDuo, caption: Self.caption, captureSize: Self.duo)
        let laurel = try #require(result.decorations.first { $0.kind == .laurel })
        let device = try #require(result.device)
        let tilt = cinema.resolved(forSlot: slot).device.tilt ?? .flat
        let top = device.frame.minY - LayoutTilt.lift(for: tilt, size: device.frame.size)
        #expect(top >= laurel.frame.maxY, "The tilted device starts under the laurel")
    }

    @Test func anIPhoneKeepsTheBoardsLook() throws {
        // On iPhone, Social Proof's laurel stays where the template puts
        // it, a corner of the phone over it, as on the board.
        let proof = ScreenshotTemplate.starter(.socialProof, id: "lumen", title: "Lumen")
        let result = engine.layout(proof, slot: 0, locale: .englishUS, displayType: .iPhone, caption: Self.caption)
        let laurel = try #require(result.decorations.first { $0.kind == .laurel })
        let declared = try #require(proof.resolved(forSlot: 0).decorations?.first { $0.isRating })
        #expect(abs(laurel.frame.minX - CGFloat(declared.x) * result.canvas.width) < 1)
        #expect(abs(laurel.frame.minY - CGFloat(declared.y) * result.canvas.height) < 1)
        #expect(abs(laurel.frame.width - CGFloat(declared.width) * result.canvas.width) < 1)
    }
}
