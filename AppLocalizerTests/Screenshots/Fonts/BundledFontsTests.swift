//
//  BundledFontsTests.swift
//  AppLocalizerTests
//

import CoreText
import Foundation
import Testing
@testable import AppLocalizer

/// The gallery's fonts ship with the app, so every face loads by name on
/// any Mac, the nearest weight is picked, and an italic the family lacks
/// is slanted.
@Suite("BundledFonts")
struct BundledFontsTests {
    @Test(arguments: BundledFonts.families.flatMap(\.faces))
    func everyFaceLoads(_ face: BundledFontFace) throws {
        let family = try #require(BundledFonts.families.first { $0.faces.contains(face) })
        let loaded = try #require(BundledFonts.font(named: family.name, weight: face.weight, italic: face.isItalic, size: 40))
        #expect(CTFontCopyPostScriptName(loaded.font) as String == face.postScriptName)
        #expect(loaded.isItalic == face.isItalic)
    }

    @Test func theNearestWeightIsPicked() throws {
        let poppins = try #require(BundledFonts.family(named: "Poppins"))
        #expect(poppins.face(weight: 900, italic: false)?.postScriptName == "Poppins-ExtraBold")
        #expect(poppins.face(weight: 300, italic: false)?.postScriptName == "Poppins-Regular")
        #expect(poppins.face(weight: 700, italic: true)?.postScriptName == "Poppins-ExtraBoldItalic", "Ties go heavier")
        let fredoka = try #require(BundledFonts.family(named: "Fredoka"))
        #expect(fredoka.face(weight: 400, italic: true)?.postScriptName == "Fredoka-Medium", "No italics: the upright face")
    }

    @Test func theCatalogDrawsBundledFontsAndSlantsMissingItalics() throws {
        let catalog = ScreenshotFontCatalog.standard
        #expect(catalog.isBundled("Anton"))
        #expect(!catalog.isBundled("SF Pro Display"))
        #expect(catalog.displayFonts.contains("Playfair Display"))
        let upright = try #require(catalog.font(named: "Lobster", weight: 400, size: 40))
        let slanted = try #require(catalog.font(named: "Lobster", weight: 400, size: 40, italic: true))
        #expect(CTFontCopyPostScriptName(slanted) as String == "Lobster-Regular")
        #expect(CTFontGetMatrix(slanted).c != 0, "A synthetic oblique")
        #expect(CTFontGetMatrix(upright).c == 0)
        #expect(catalog.covers("Anton", "Ünïcødé"))
    }

    @Test func boldonseDrawsLatinCapsAndFallsBackHeavier() {
        let catalog = ScreenshotFontCatalog.standard
        #expect(catalog.isBundled("Boldonse"))
        #expect(catalog.covers("Boldonse", "STRASSE ẞ İSTANBUL ĞÜŞ ÇÃÕ"))
        #expect(!catalog.covers("Boldonse", "ПРИВЕТ"))
        #expect(!catalog.covers("Boldonse", "毎日"))
        // Its fallback is heavy like it; other families keep their weight.
        #expect(catalog.fallbackWeight(for: "Boldonse") == 800)
        #expect(catalog.fallbackWeight(for: "Anton") == nil)
        #expect(catalog.fallbackWeight(for: "SF Pro Display") == nil)
    }
}
