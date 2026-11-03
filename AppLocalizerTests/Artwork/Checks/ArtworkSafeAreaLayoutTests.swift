//
//  ArtworkSafeAreaLayoutTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The header, search and 16:9 images as the design canvas lays them out
/// (board 32): the header is the app's icon and name centered with its
/// line under them and no phone, inside what iPhone shows; search results
/// is the headline on one side and the phone on the other; the 16:9 image
/// is the header's wordmark over the phone. Everything stays in the safe
/// area, left to right and mirrored.
@MainActor
@Suite("Artwork safe area layout")
struct ArtworkSafeAreaLayoutTests {
    private typealias Fixtures = ArtworkCheckFixtures

    private static func unit(_ kind: AutopilotArtworkKind) -> CGFloat { kind.pixelSize.cgSize.width / 100 }

    @Test func theSafeAreasAreTheCanvassNumbers() {
        #expect(ArtworkSafeArea.rect(for: .header) == CGRect(x: 653, y: 362, width: 2534, height: 1284))
        #expect(ArtworkSafeArea.rect(for: .search) == CGRect(x: 0, y: 0, width: 3840, height: 2560))
        #expect(ArtworkSafeArea.rect(for: .wide) == CGRect(x: 891, y: 354, width: 3462, height: 2596))
        for kind in AutopilotArtworkKind.allCases {
            let rect = ArtworkSafeArea.rect(for: kind)
            // Centered across, inside the canvas, down to the bottom.
            #expect(abs(rect.midX - kind.pixelSize.cgSize.width / 2) <= 1)
            #expect(CGRect(origin: .zero, size: kind.pixelSize.cgSize).contains(rect))
            #expect(abs(rect.maxY - kind.pixelSize.cgSize.height) <= 1)
        }
        // Show iPhone Area marks the header's rectangle.
        let header = ArtworkSafeArea.fraction(for: .header)
        #expect(abs(header.minX - ArtworkSafeArea.iPhoneHeaderSide) < 0.001)
        #expect(abs(header.minY - ArtworkSafeArea.iPhoneHeaderTop) < 0.001)
    }

    @Test(arguments: AutopilotArtworkKind.allCases, [StoreLocale.englishUS, .arabic, .german])
    func phonesAndTextStayInsideTheSafeArea(kind: AutopilotArtworkKind, locale: StoreLocale) {
        let line = locale == .german ? "Dein Tag, klar geplant" : locale == .arabic ? "يومك منظم" : "Your week, sorted"
        let layout = Fixtures.layout(kind, headline: line, locale: locale)
        let safe = layout.safeArea.insetBy(dx: -1, dy: -1)
        #expect(layout.safeArea == ArtworkSafeArea.rect(for: kind))
        #expect(layout.headlineFits)
        #expect(!layout.lines.isEmpty)
        if let focal = layout.visibleFocalFrame {
            #expect(safe.contains(focal), "\(kind) \(locale.code): phones \(focal) outside \(layout.safeArea)")
        }
        for line in layout.lines {
            #expect(safe.contains(line.frame), "\(kind) \(locale.code): line \(line.frame) outside")
        }
        if let label = layout.appLabel {
            #expect(safe.contains(label.iconFrame.union(label.name.frame)))
        }
        // The text never runs under the phones.
        for phone in layout.phones {
            for line in layout.textLines {
                #expect(!line.frame.intersects(phone.bounds), "\(kind) \(locale.code): \(line.text) under the phone")
            }
        }
        #expect(ArtworkChecker().safeAreaChecks(Fixtures.input(layout, line: line, locale: locale)).isEmpty)
    }

    @Test(arguments: [StoreLocale.englishUS, .arabic])
    func theHeaderIsTheIconAndNameCenteredWithTheLineUnder(locale: StoreLocale) throws {
        let layout = Fixtures.layout(.header, headline: locale == .arabic ? "يومك منظم" : "Your week, sorted", locale: locale)
        let unit = Self.unit(.header)
        #expect(layout.phones.isEmpty, "No phone on the header")
        let label = try #require(layout.appLabel)
        let wordmark = label.iconFrame.union(label.name.frame)
        #expect(abs(wordmark.midX - layout.size.width / 2) < 2)
        #expect(abs(label.iconFrame.minY - layout.size.height * 0.36) < 1)
        #expect(abs(label.iconFrame.width - 7 * unit) < 1)
        #expect(abs(label.name.pixelSize - 7.4 * unit) < 0.1)
        #expect((1...2).contains(layout.lines.count))
        for line in layout.lines {
            #expect(abs(line.frame.midX - layout.size.width / 2) < 2)
            #expect(abs(line.frame.width - 48 * unit) < 1)
            #expect(line.frame.minY >= wordmark.maxY)
            #expect(line.alignment == .center)
        }
        // In Arabic the icon goes on the right of the name.
        if layout.isMirrored {
            #expect(label.iconFrame.minX > label.name.frame.maxX)
        } else {
            #expect(label.iconFrame.maxX < label.name.frame.minX)
        }
    }

    @Test func aHeaderWithoutALineIsTheWordmarkAlone() throws {
        let layout = Fixtures.layout(.header, headline: "")
        #expect(layout.lines.isEmpty)
        #expect(layout.headlineBox == .zero)
        let label = try #require(layout.appLabel)
        #expect(layout.safeArea.insetBy(dx: -1, dy: -1).contains(label.iconFrame.union(label.name.frame)))

        let bare = Fixtures.layout(.header, headline: "", appName: nil)
        #expect(bare.appLabel == nil && bare.lines.isEmpty && bare.phones.isEmpty)
    }

    @Test func theWideImageIsTheWordmarkOverThePhone() throws {
        let layout = Fixtures.layout(.wide, headline: "Your week, sorted")
        let label = try #require(layout.appLabel)
        #expect(abs(label.iconFrame.minY - layout.size.height * 0.16) < 1)
        let phone = try #require(layout.phones.first)
        #expect(layout.phones.count == 1)
        #expect(!phone.isBare && phone.rotation == 0)
        #expect(abs(phone.frame.midX - layout.size.width / 2) < 2)
        #expect(phone.frame.minY >= (layout.lines.last?.frame.maxY ?? 0))
        #expect(phone.frame.maxY > layout.size.height, "It runs off the bottom")

        let bare = try #require(Fixtures.layout(.wide, headline: "Your week, sorted", shows: .ui).phones.first)
        #expect(bare.isBare)
        #expect(abs(bare.screen.width - 30 * Self.unit(.wide)) < 1)
        #expect(Fixtures.layout(.wide, headline: "Your week, sorted", shows: .scene).phones.isEmpty)
    }

    @Test func searchIsTheHeadlineThenThePhone() throws {
        let layout = Fixtures.layout(.search, headline: "Your week, sorted")
        let unit = Self.unit(.search)
        let line = try #require(layout.lines.first)
        #expect(abs(line.frame.minX - 7 * unit) < 1)
        #expect(abs(line.frame.minY - 9 * unit) < 1)
        #expect(abs(line.frame.width - 46 * unit) < 1)
        #expect(layout.lines.count <= 4)
        let phone = try #require(layout.phones.first)
        #expect(!phone.isBare)
        #expect(abs(phone.frame.minX - 57 * unit) < 1)
        #expect(abs(phone.screen.width - 30 * unit) < 1)
        #expect(phone.rotation == -6)
        // The icon and name at the bottom.
        let label = try #require(layout.appLabel)
        #expect(abs(label.iconFrame.width - 5.4 * unit) < 1)
        #expect(abs(label.iconFrame.maxY - layout.size.height * 0.9) < 1)
        #expect(abs(label.iconFrame.minX - 7 * unit) < 1)
    }

    @Test func searchWithoutADeviceIsTheBareScreen() throws {
        let layout = Fixtures.layout(.search, headline: "Your week, sorted", shows: .ui)
        let unit = Self.unit(.search)
        let phone = try #require(layout.phones.first)
        #expect(phone.isBare)
        #expect(abs(phone.frame.minX - 55 * unit) < 1)
        #expect(abs(phone.screen.width - 36 * unit) < 1)
        #expect(abs(phone.screen.height - 50 * unit) < 1, "Cut at 50 units")
        #expect(phone.rotation == -4)
    }

    @Test func aSceneHasNoAppAndABiggerHeadline() throws {
        let layout = Fixtures.layout(.search, headline: "Your week, sorted", shows: .scene)
        let unit = Self.unit(.search)
        #expect(layout.phones.isEmpty)
        let scene = try #require(layout.scene)
        #expect(scene.hasLandscape && !scene.isMotion)
        let line = try #require(layout.lines.first)
        #expect(abs(line.frame.minY - 14 * unit) < 1)
        #expect(abs(line.frame.width - 56 * unit) < 1)
        #expect(Fixtures.layout(.header, headline: "Your week, sorted", shows: .scene).scene?.hasLandscape == true)
        // Motion adds the light, without the landscape.
        let moving = try #require(Fixtures.layout(.search, headline: "Your week, sorted", isMotion: true).scene)
        #expect(moving.isMotion && !moving.hasLandscape)
        #expect(Fixtures.layout(.search, headline: "Your week, sorted").scene == nil)
    }

    @Test func rightToLeftMirrorsTheLayoutButNotTheCaptures() throws {
        let english = Fixtures.layout(.search, headline: "Your week, sorted")
        let arabic = Fixtures.layout(.search, headline: "يومك منظم", locale: .arabic)
        #expect(!english.isMirrored)
        #expect(arabic.isMirrored)
        let englishPhone = try #require(english.phones.first)
        let arabicPhone = try #require(arabic.phones.first)
        // Text first, then the phone, in reading order.
        #expect(english.lines[0].frame.maxX <= englishPhone.bounds.minX)
        #expect(arabic.lines[0].frame.minX >= arabicPhone.bounds.maxX)
        #expect(arabic.lines[0].alignment == .right)
        #expect(arabicPhone.rotation == -englishPhone.rotation)
        #expect(abs(arabicPhone.frame.minX - (arabic.size.width - englishPhone.frame.maxX)) < 1)
        // The phone keeps its shape: the capture is never flipped.
        #expect(abs(arabicPhone.frame.width - englishPhone.frame.width) < 1)
        let label = try #require(arabic.appLabel)
        #expect(abs(label.iconFrame.maxX - (arabic.size.width - 7 * Self.unit(.search))) < 1)
    }

    @Test func aLongGermanWordShrinksInsideItsColumn() throws {
        let line = "Haushaltsbuchführung"
        let layout = Fixtures.layout(.search, headline: line, locale: .german)
        let phone = try #require(layout.phones.first)
        #expect(layout.headline.size < layout.headline.fullSize)
        #expect(layout.lines.allSatisfy { !$0.frame.intersects(phone.bounds) && layout.safeArea.insetBy(dx: -1, dy: -1).contains($0.frame) })
    }

    @Test func highlightAndEmphasisStillApply() throws {
        let template = ScreenshotTemplate.starter(.highlight, id: "lumen", title: "Lumen")
        let layout = Fixtures.layout(.search, headline: "Your week, sorted", template: template)
        let line = try #require(layout.lines.first)
        #expect(line.highlight != nil)
        #expect(layout.safeArea.insetBy(dx: -1, dy: -1).contains(line.frame))
    }
}
#endif
