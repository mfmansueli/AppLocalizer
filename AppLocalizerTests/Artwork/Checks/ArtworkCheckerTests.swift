//
//  ArtworkCheckerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The checks on a rendered header or search image: Apple's rules as
/// errors that block its push, the rest as warnings.
@MainActor
@Suite("Artwork checks")
struct ArtworkCheckerTests {
    private typealias Fixtures = ArtworkCheckFixtures
    private let checker = ArtworkChecker()

    private func checks(_ input: ArtworkCheckInput, read: [ArtworkReadText]? = nil) -> [ArtworkCheck] {
        checker.checks(input, read: read)
    }

    // MARK: - Errors

    @Test func aPriceInTheLineIsAnError() throws {
        let layout = Fixtures.layout(.header, headline: "Nur 4,99 €", locale: .german)
        let found = checks(Fixtures.input(layout, line: "Nur 4,99 €", locale: .german))
        let price = try #require(found.first)
        #expect(price.kind == .price)
        #expect(price.severity == .error)
        #expect(price.shortReason == "Price")
        #expect(price.text == "German header: ‘4,99 €’ — prices and currency symbols aren’t allowed here.")
        #expect(!ArtworkChecker.canPush(found))
    }

    @Test func aDiscountSaysWhatAndWhere() throws {
        let layout = Fixtures.layout(.header, headline: "Jetzt −50%", locale: .german)
        let discount = try #require(checks(Fixtures.input(layout, line: "Jetzt −50%", locale: .german)).first { $0.kind == .discount })
        #expect(discount.text == "German header: ‘−50%’ — discounts and percentages aren’t allowed here.")
    }

    @Test func aURLReadInTheRenderIsAnError() throws {
        let layout = Fixtures.layout(.search, headline: "Your week, sorted")
        // Text the render shows outside the phone: in the background.
        let read = [ArtworkReadText(text: "lumen.app", frame: CGRect(x: 900, y: 1700, width: 300, height: 60), confidence: 0.9)]
        let url = try #require(checks(Fixtures.input(layout, line: "Your week, sorted"), read: read).first)
        #expect(url.kind == .url)
        #expect(url.severity == .error)
        #expect(url.text == "English (U.S.) search image: ‘lumen.app’ — website addresses aren’t allowed here.")
    }

    @Test func theSameTextOnThePhonesScreenIsOnlyAWarning() throws {
        let layout = Fixtures.layout(.search, headline: "Your week, sorted")
        let screen = try #require(layout.phones.first?.screen)
        let read = [ArtworkReadText(text: "Upgrade for $4.99", frame: CGRect(x: screen.midX - 100, y: screen.midY, width: 200, height: 40), confidence: 0.9)]
        let found = checks(Fixtures.input(layout, line: "Your week, sorted"), read: read)
        let price = try #require(found.first { $0.kind == .price })
        #expect(price.severity == .warning)
        #expect(price.text.contains("on the phone’s screen"))
        #expect(ArtworkChecker.canPush(found))
    }

    @Test func editorsChoiceIsAnError() throws {
        let line = "Editor’s Choice journal"
        let layout = Fixtures.layout(.wide, headline: line)
        let recognition = try #require(checks(Fixtures.input(layout, line: line)).first)
        #expect(recognition.kind == .appleRecognition)
        #expect(recognition.severity == .error)
        #expect(recognition.text == "English (U.S.) header and search image: ‘Editor's Choice’ — "
            + "Apple’s recognitions aren’t allowed here; the App Store shows them itself.")
    }

    @Test func foundInTheLineAndTheRenderItCountsOnce() {
        let layout = Fixtures.layout(.header, headline: "Also on Android")
        let read = [ArtworkReadText(text: "Also on Android", frame: layout.headlineBox, confidence: 0.95)]
        let found = checks(Fixtures.input(layout, line: "Also on Android"), read: read).filter { $0.kind == .otherPlatform }
        #expect(found.count == 1)
    }

    @Test func anAlphaChannelIsAnError() throws {
        let layout = Fixtures.layout(.header, headline: "")
        let image = try #require(Fixtures.image(width: 384, height: 165, alpha: true) { context, size in
            context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: size.width / 2, height: size.height))
        })
        let transparency = try #require(checks(Fixtures.input(layout, line: "", image: image)).first { $0.kind == .transparency })
        #expect(transparency.severity == .error)
        #expect(transparency.text == "English (U.S.) header: parts of it are see-through — Apple takes no alpha or transparency here.")
    }

    @Test func aPNGWithAnAlphaChannelIsAnErrorEvenWhenOpaque() throws {
        let layout = Fixtures.layout(.header, headline: "")
        let image = try #require(Fixtures.solid(CGColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1), alpha: true))
        var input = Fixtures.input(layout, line: "", image: image)
        input.pngData = ScreenshotPNG.data(image)
        let transparency = try #require(checks(input).first { $0.kind == .transparency })
        #expect(transparency.text.contains("has an alpha channel"))
    }

    @Test func theFlattenedRenderHasNoAlpha() throws {
        let layout = Fixtures.layout(.header, headline: "Your calm place")
        let image = try #require(Fixtures.render(layout))
        var input = Fixtures.input(layout, line: "Your calm place", image: image)
        input.pngData = ScreenshotPNG.data(image)
        #expect(!checks(input).contains { $0.kind == .transparency })
    }

    // MARK: - Warnings

    @Test func aLongGermanSearchHeadlineIsAWarning() throws {
        let line = "Behalte deine Gewohnheiten jeden Tag mühelos im Blick"
        let layout = Fixtures.layout(.search, headline: line, locale: .german)
        let found = checks(Fixtures.input(layout, line: line, locale: .german))
        let long = try #require(found.first { $0.kind == .searchHeadlineLength })
        #expect(long.severity == .warning)
        #expect(long.text == "German search image: ‘\(line)’ is 8 words, 53 characters. A search headline reads best in 3 to 5 words, about 32 characters.")
        #expect(ArtworkChecker.canPush(found))
    }

    @Test func aHeaderLineOverThreeWordsIsAWarning() {
        let line = "Your calm place to write"
        let layout = Fixtures.layout(.header, headline: line)
        let kinds = checks(Fixtures.input(layout, line: line)).map(\.kind)
        #expect(kinds.contains(.headerTextLength))
        #expect(!kinds.contains(.searchHeadlineLength))
    }

    @Test func lowContrastTextIsAWarning() throws {
        let template = Fixtures.template(background: "#FFFFFF", ink: "#D9D9D9")
        let layout = Fixtures.layout(.search, headline: "Your week, sorted", template: template)
        let contrast = try #require(checks(Fixtures.input(layout, line: "Your week, sorted", template: template)).first { $0.kind == .textContrast })
        #expect(contrast.severity == .warning)
        #expect(contrast.text.hasPrefix("English (U.S.) search image: the headline is hard to read on what’s behind it (1"))
        #expect(contrast.text.hasSuffix(":1; aim for 3:1 or more)."))
    }

    @Test func aWhiteImageMeltsIntoTheLightPage() throws {
        let template = Fixtures.template(background: "#FDFDFD", ink: "#1A1A1A")
        let layout = Fixtures.layout(.header, headline: "", template: template)
        let image = try #require(Fixtures.solid(CGColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1)))
        let edges = checks(Fixtures.input(layout, line: "", image: image, template: template)).filter { $0.kind == .edgeContrast }
        #expect(edges.count == 1)
        #expect(edges.first?.text.contains("in Light Mode its edges melt into the App Store page") == true)
    }

    @Test func aBlackImageMeltsIntoTheDarkPage() throws {
        let template = Fixtures.template(background: "#050505")
        let layout = Fixtures.layout(.header, headline: "", template: template)
        let image = try #require(Fixtures.solid(CGColor(red: 0.02, green: 0.02, blue: 0.02, alpha: 1)))
        let edges = checks(Fixtures.input(layout, line: "", image: image, template: template)).filter { $0.kind == .edgeContrast }
        #expect(edges.map(\.text).first?.contains("in Dark Mode") == true)
    }

    /// The header has no phone now: its icon and name leave the part
    /// iPhone shows; the 16:9 image's phone leaves the sides.
    @Test func whatLeavesTheSafeAreaIsAWarning() throws {
        var header = Fixtures.layout(.header, headline: "Your calm place")
        let label = try #require(header.appLabel)
        header.appLabel?.iconFrame.origin.x = 120
        header.appLabel?.name.frame.origin.x = 120 + label.iconFrame.width
        let named = try #require(checks(Fixtures.input(header, line: "Your calm place")).first { $0.kind == .safeArea })
        #expect(named.text == "English (U.S.) header: the app’s icon and name run outside the center safe area, so some devices cut them off.")

        var wide = Fixtures.layout(.wide, headline: "Your calm place")
        try #require(!wide.phones.isEmpty)
        wide.phones[0].frame.origin.x = 120
        let phones = try #require(checks(Fixtures.input(wide, line: "Your calm place")).first { $0.kind == .safeArea })
        #expect(phones.text.hasPrefix("English (U.S.) "))
        #expect(phones.text.contains(": the phones run outside the center safe area, so some devices cut them off."))
    }

    @Test func aHeaderThatSharesNothingWithTheScreenshotsIsAWarning() throws {
        let layout = Fixtures.layout(.header, headline: "Your calm place")
        let other = Fixtures.template(background: "#F2C94C", font: "Georgia")
        let look = try #require(checks(Fixtures.input(layout, line: "Your calm place", screenshotTemplate: other)).first { $0.kind == .sharedLook })
        #expect(look.text.contains("doesn’t share the first screenshot’s colors and typeface"))
        // The direction's own template shares both.
        let same = Fixtures.input(layout, line: "Your calm place", screenshotTemplate: Fixtures.template(font: layout.lines.first?.fontName))
        #expect(!checks(same).contains { $0.kind == .sharedLook })
    }

    // MARK: - Passing, and Vision

    @Test func aCleanRenderPassesEveryCheck() async throws {
        for kind in AutopilotArtworkKind.allCases {
            // The 16:9 image is a header too: a short line.
            let line = kind == .search ? "Plan your week in seconds" : "Your week, sorted"
            let layout = Fixtures.layout(kind, headline: line)
            let image = try #require(Fixtures.render(layout))
            var input = Fixtures.input(layout, line: line, image: image, screenshotTemplate: Fixtures.template(font: layout.lines.first?.fontName))
            input.pngData = ScreenshotPNG.data(image)
            let found = await checker.checks(input)
            #expect(found.isEmpty, "\(kind): \(found.map(\.text))")
        }
    }

    @Test func visionReadsAURLDrawnIntoTheImage() async throws {
        // The URL is in the pixels only: the text layers are cleared.
        let drawn = Fixtures.layout(.search, headline: "Visit lumenjournal.com")
        let image = try #require(Fixtures.render(drawn))
        var layout = drawn
        layout.lines = []
        let found = await checker.checks(Fixtures.input(layout, line: "", image: image))
        let url = try #require(found.first { $0.kind == .url })
        #expect(url.severity == .error)
        #expect(url.text.localizedCaseInsensitiveContains("lumenjournal.com"))
    }

    @Test func withoutVisionTheTextLayersAreStillChecked() async throws {
        let blind = ArtworkChecker(reader: { _, _ in nil })
        let layout = Fixtures.layout(.header, headline: "Only $4.99")
        let image = try #require(Fixtures.render(layout))
        let found = await blind.checks(Fixtures.input(layout, line: "Only $4.99", image: image))
        #expect(found.first?.kind == .price)
    }
}
#endif
