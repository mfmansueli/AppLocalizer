//
//  TemplateStarterTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The gallery's 12 templates: three per style, each a valid template
/// that every check accepts, with slots past the fifth repeating 2–5.
@MainActor
@Suite("TemplateStarter")
struct TemplateStarterTests {
    private let applier = TemplateOperationApplier()

    @Test func theGalleryHasThreeTemplatesPerStyle() {
        #expect(TemplateStarter.allCases.count == 12)
        for style in TemplateStarter.Style.allCases {
            #expect(TemplateStarter.starters(in: style).count == 3, "\(style.title)")
        }
        #expect(TemplateStarter.starters(in: nil) == TemplateStarter.allCases)
        #expect(TemplateStarter.simple == [.above, .band, .panorama])
        #expect(TemplateStarter.starters(in: .elegant) == [.cinema, .spotlight, .editorial])
    }

    @Test(arguments: TemplateStarter.allCases)
    func everyTemplatePassesTheApplier(_ starter: TemplateStarter) {
        let template = ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
        // A no-op replace runs every consistency check on the whole template.
        let result = applier.applying([.replace("fit.shrink", with: .bool(template.fit.shrink))], to: template)
        if case let .failure(refusals) = result {
            Issue.record("\(starter.title): \(refusals.items.map(\.reason))")
        }
        #expect(template.name == "Lumen · \(starter.title)")
        #expect(template.slots.count == 5)
    }

    @Test(arguments: TemplateStarter.allCases)
    func everyTemplateSurvivesJSON(_ starter: TemplateStarter) throws {
        let template = ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
        let data = try JSONEncoder().encode(template)
        let decoded = try JSONDecoder().decode(ScreenshotTemplate.self, from: data)
        #expect(decoded == template)
        #expect(decoded.contentHash == template.contentHash)
    }

    @Test func theSimpleTemplatesKeepTheirPlainLook() {
        for starter in TemplateStarter.simple {
            let template = ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
            #expect(!template.showsRatings)
            for slot in template.slots.indices {
                let resolved = template.resolved(forSlot: slot)
                #expect(resolved.device.tilt?.isFlat ?? true, "\(starter.title) slot \(slot + 1)")
                #expect(resolved.decorations?.isEmpty ?? true)
                #expect(resolved.caption.headline.emphasis == nil)
            }
        }
    }

    @Test func slotsPastTheFifthRepeatTwoToFiveWithoutRatings() {
        let template = ScreenshotTemplate.starter(.cinema, id: "lumen", title: "Lumen", slotCount: 8)
        #expect(template.slots.count == 8)
        // Slot 2 has Cinema's laurel; slot 6 repeats slot 2 without it.
        #expect(template.resolved(forSlot: 1).decorations?.contains(where: \.isRating) == true)
        let sixth = template.resolved(forSlot: 5)
        #expect(sixth.decorations?.contains(where: \.isRating) != true)
        #expect(sixth.device.width == template.resolved(forSlot: 1).device.width)
        #expect(template.resolved(forSlot: 6).device.tilt == template.resolved(forSlot: 2).device.tilt)
    }

    @Test func templatesUseTheirBundledFonts() {
        let fonts: [TemplateStarter: String] = [
            .boldStack: "Archivo Black", .poster: "Anton", .cinema: "Playfair Display", .playful: "Lobster", .highlight: "Fredoka",
        ]
        for (starter, font) in fonts {
            let template = ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
            #expect(template.caption.headline.font == font)
            #expect(BundledFonts.isBundled(font))
        }
    }

    @Test func cinemaPutsTheCaptionBelowALeaningPhone() {
        let template = ScreenshotTemplate.starter(.cinema, id: "lumen", title: "Lumen")
        #expect(template.caption.placement == .below)
        #expect(template.device.tilt == TemplateTilt(rotate: -9, turn: 18, lean: 12))
        #expect(template.resolved(forSlot: 2).device.tilt == TemplateTilt(rotate: 8, turn: -18, lean: 12))
        #expect(template.caption.headline.emphasis?.line == .last)
    }

    @Test func theTagsAndSummaryDescribeEachTemplate() {
        for starter in TemplateStarter.allCases {
            #expect(!starter.summary.isEmpty)
            #expect(!starter.tags.isEmpty, "\(starter.title)")
        }
    }
}
