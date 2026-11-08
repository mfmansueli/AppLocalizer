//
//  AutopilotArtworkOnePlaceTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The plan's "Header 21:9 only" and "Search results 3:2 only": what a
/// run makes, what the brief asks for, the texts it needs, and the other
/// place, which keeps what it shows.
@MainActor
@Suite("Only the header or only search results")
struct AutopilotArtworkOnePlaceTests {
    private static let earlierLook = ScreenshotsSampleData.template

    private static func file(_ kind: AutopilotArtworkKind, _ locale: String, _ id: String) -> ExtrasArtworkFile {
        ExtrasArtworkFile(kind: kind, locale: locale, fileID: id, headline: "", fits: true, byteCount: 1000)
    }

    /// Made earlier in Quiet Indigo: a header and a moving search image of
    /// the app's screen, from its own pages.
    private static var earlier: ScreenshotExtras {
        ScreenshotExtras(
            directionName: "Quiet Indigo", madeAt: .distantPast, artworkSize: .headerAndSearch, artworkTemplate: earlierLook,
            artworkDesign: AutopilotArtworkDesign(pages: [.header: "<p>old header</p>", .search: "<p>old search</p>"]),
            searchSlot: 2, artworkShows: .ui, artworkMotion: .loop,
            artwork: [file(.header, "en-US", "h-old"), file(.search, "en-US", "s-old"), file(.search, "de-DE", "s-old-de")]
        )
    }

    /// This run's header in Warm Paper, still.
    private static var newHeader: ScreenshotExtras {
        ScreenshotExtras(
            directionName: "Warm Paper", madeAt: AutopilotTestFixtures.now, artworkSize: .headerOnly,
            artworkDesign: AutopilotArtworkDesign(pages: [.header: "<p>new header</p>"]), artworkMotion: .still,
            artwork: [file(.header, "en-US", "h-new"), file(.header, "de-DE", "h-new-de")]
        )
    }

    // MARK: - The choice

    @Test func eachSizeSaysWhatItMakesAndWhatItLeaves() {
        #expect(AutopilotArtworkSize.allCases.map(\.title) == [
            "Header 21:9 and search 3:2", "Header 21:9 only", "Search results 3:2 only", "One 16:9 image for both",
        ])
        let header = AutopilotArtworkSize.headerOnly
        #expect(header.kinds == [.header])
        #expect(header.headerKind == .header)
        #expect(header.searchKind == nil)
        #expect(header.keptKind == .search)
        #expect(header.roles == [.header])
        #expect(header.allowsMotion)

        let search = AutopilotArtworkSize.searchOnly
        #expect(search.kinds == [.search])
        #expect(search.headerKind == nil)
        #expect(search.searchKind == .search)
        #expect(search.keptKind == .header)
        #expect(search.roles == [.search])
        #expect(search.allowsMotion)

        #expect(AutopilotArtworkSize.headerAndSearch.keptKind == nil)
        #expect(AutopilotArtworkSize.wide.keptKind == nil)
        #expect(ArtworkTextRole.roles(for: .headerOnly) == [.header])
    }

    @Test func thePlanMakesOnlyThatImageAndKeepsTheChoice() throws {
        var plan = StudioDebugRuns.plan
        plan.alsoMakes = AutopilotExtras(makesArtwork: true, artworkSize: .headerOnly)
        #expect(plan.artworkKinds == [.header])
        let decoded = try JSONDecoder().decode(AutopilotPlan.self, from: JSONEncoder().encode(plan))
        #expect(decoded.alsoMakes.artworkSize == .headerOnly)
        #expect(plan.artworkMadeTitle == "header artwork")
        #expect(plan.directionTitle == "template", "The screenshots' template first")
        #expect(AutopilotArtworkSize.headerOnly.directionTitle == "header")
        #expect(plan.briefExtrasLines == ["Brief also asks for a 21:9 header (3840 × 1646) in each direction"])
        #expect(AutopilotEstimate.summary(for: plan, design: .none).hasPrefix("120 captures in 12 languages, plus header artwork · "))

        plan.alsoMakes.setArtworkSize(.searchOnly)
        #expect(plan.artworkKinds == [.search])
        #expect(plan.briefExtrasLines == ["Brief also asks for a 3:2 search results image (3840 × 2560) in each direction"])
    }

    /// Either one alone can be a loop; only the 16:9 image can't.
    @Test func eitherOneAloneCanMove() {
        var extras = AutopilotExtras(makesArtwork: true, artworkSize: .headerOnly)
        extras.setMotion(.loop)
        #expect(extras.artworkSize == .headerOnly, "A loop keeps the header alone")
        #expect(extras.makesMotion)
        extras.setArtworkSize(.searchOnly)
        #expect(extras.makesMotion)
        #expect(extras.artworkSize.movingTitle == "moving search results artwork")
        extras.setArtworkSize(.wide)
        #expect(!extras.makesMotion)
        extras.setMotion(.loop)
        #expect(extras.artworkSize == .headerAndSearch)
    }

    // MARK: - The brief

    @Test func theBriefAsksOnlyForTheOneImage() {
        let header = AutopilotArtworkBrief(AutopilotExtras(makesArtwork: true, artworkSize: .headerOnly))
        #expect(header.rows.map(\.title) == ["Header · 21:9", "Safe area", "The app’s own look", "About the app", "Still image", "Words"])
        #expect(header.rows.first { $0.title == "The app’s own look" }?.text.hasSuffix("The other place keeps what it shows now.") == true)
        let safeArea = AutopilotArtworkBrief.safeAreaRow(AutopilotExtras(makesArtwork: true, artworkSize: .headerOnly)).text
        #expect(safeArea.hasPrefix("On the header, keep the app name"), "\(safeArea)")
        #expect(!safeArea.contains("search"), "\(safeArea)")

        #expect(header.rows.first { $0.title == "About the app" }?.text.contains("search headline") == false)
        var moving = AutopilotExtras(makesArtwork: true, artworkSize: .headerOnly)
        moving.setMotion(.loop)
        let motion = AutopilotArtworkBrief(moving).rows.first { $0.title == "Motion · 20-second loop" }?.text
        #expect(motion?.contains("float") == false, "The header alone has no phone to float")
        #expect(!ScreenshotStudioModel.artworkMotionNote(moving).contains("float"))
        #expect(ScreenshotStudioModel.artworkMotionNote(moving).hasSuffix("Apple plays it on repeat, muted, at 21:9."))

        let search = AutopilotArtworkBrief(AutopilotExtras(makesArtwork: true, artworkSize: .searchOnly))
        #expect(search.rows.map(\.title) == ["Search results · 3:2", "Safe area", "The app’s own look", "About the app", "Still image", "Words"])
    }

    @Test func getDesignBriefLeavesTheOtherPlaceOut() async throws {
        let headerRun = StudioDebugExtras.run(.design, size: .headerOnly)
        let header = try #require(try await MCPAutopilotFixtures(headerRun).call(GetDesignBriefTool(), ["run": "run-debug"]).result["extras"])
        #expect(header["canvases"]?.arrayValue?.compactMap { $0["kind"]?.stringValue } == ["header"])
        #expect(header["header"] == "21:9")
        #expect(header["search"] == nil)
        #expect(header["roles"]?["header"] != nil)
        #expect(header["roles"]?["search"] == nil)
        let only = try #require(header["onlyThis"]?.stringValue)
        #expect(only.hasPrefix("This run makes only the product page header. The other place keeps what it shows now"))
        #expect(header["aboutTheApp"]?.stringValue?.hasPrefix("It is about this app") == true)
        #expect(header["aboutTheApp"]?.stringValue?.contains("search headline") == false, "The header has no search headline")
        #expect(header["captures"]?.stringValue?.contains("in it are the real picked captures") == true)

        let searchRun = StudioDebugExtras.run(.design, size: .searchOnly)
        let search = try #require(try await MCPAutopilotFixtures(searchRun).call(GetDesignBriefTool(), ["run": "run-debug"]).result["extras"])
        #expect(search["canvases"]?.arrayValue?.compactMap { $0["kind"]?.stringValue } == ["search"])
        #expect(search["header"] == nil)
        #expect(search["roles"]?["header"] == nil)
        #expect(search["onlyThis"]?.stringValue?.hasPrefix("This run makes only the search results image.") == true)
        #expect(search["aboutTheApp"]?.stringValue?.contains("the search headline names its core task") == true)

        let bothRun = StudioDebugExtras.run(.design)
        let both = try #require(try await MCPAutopilotFixtures(bothRun).call(GetDesignBriefTool(), ["run": "run-debug"]).result["extras"])
        #expect(both["onlyThis"] == nil)
        #expect(both["aboutTheApp"]?.stringValue?.hasPrefix("Both are about this app") == true)
    }

    @Test func theStepsNameWhatTheRunDesigns() {
        var plan = StudioDebugRuns.plan
        plan.runChoice.makesScreenshots = false
        plan.alsoMakes = AutopilotExtras(makesArtwork: true, artworkSize: .searchOnly)
        #expect(AutopilotNextStep.designHow(plan: plan).contains("so only the search results image as your own HTML pages"))
        let note = GetDesignBriefTool.noScreenshots(makesArtwork: true, stylesPreview: false, places: AutopilotArtworkSize.headerOnly.mcpPlaces)
        #expect(note.contains("Design only the header: send each direction"))
    }

    // MARK: - Texts

    @Test func theHeaderAloneNeedsNoSearchHeadline() {
        func needs(_ size: AutopilotArtworkSize) -> [AutopilotArtworkTextNeed] {
            AutopilotArtworkTextChecker(
                template: ScreenshotsSampleData.template, texts: ArtworkTextBook(), size: size, catalog: ScreenshotsTestFixtures.fonts
            ).needs(locales: ["en-US", "de-DE"])
        }
        #expect(needs(.headerOnly).isEmpty, "Its line is optional")
        #expect(needs(.searchOnly).map(\.role) == [.search, .search])
        #expect(needs(.searchOnly).map(\.locale) == ["en-US", "de-DE"])
    }

    // MARK: - The other place

    @Test func onlyTheHeaderKeepsTheSearchImageMadeBefore() {
        var made = Self.newHeader
        made.keepOtherPlace(from: Self.earlier, making: .headerOnly)
        #expect(made.artworkSize == .headerAndSearch, "Both places have artwork again")
        #expect(made.artwork.map(\.fileID) == ["h-new", "h-new-de", "s-old", "s-old-de"])
        #expect(made.keptPlace == ExtrasArtworkPlace(
            kind: .search, directionName: "Quiet Indigo", template: Self.earlierLook, page: "<p>old search</p>", shows: .ui, searchSlot: 2,
            motion: .loop
        ))
        #expect(made.place(.search) == made.keptPlace)
        let header = made.place(.header)
        #expect(header.directionName == "Warm Paper")
        #expect(header.page == "<p>new header</p>")
        #expect(header.motion == .still)
    }

    /// The next run makes only search: the header just made is kept, drawn
    /// as this run made it.
    @Test func aPlaceKeptBeforeIsKeptAsItWas() {
        var first = Self.newHeader
        first.keepOtherPlace(from: Self.earlier, making: .headerOnly)
        var next = ScreenshotExtras(
            directionName: "Bright Day", madeAt: AutopilotTestFixtures.now, artworkSize: .searchOnly, artwork: [Self.file(.search, "en-US", "s-new")]
        )
        next.keepOtherPlace(from: first, making: .searchOnly)
        #expect(next.artwork.map(\.fileID) == ["s-new", "h-new", "h-new-de"])
        #expect(next.keptPlace?.kind == .header)
        #expect(next.keptPlace?.directionName == "Warm Paper")
        #expect(next.keptPlace?.page == "<p>new header</p>")
        #expect(next.place(.search).directionName == "Bright Day")
    }

    @Test func nothingIsKeptWithoutThatPlacesOwnImage() {
        var wide = Self.earlier
        wide.artworkSize = .wide
        wide.artwork = [Self.file(.wide, "en-US", "w-old")]
        var made = Self.newHeader
        made.keepOtherPlace(from: wide, making: .headerOnly)
        #expect(made.artworkSize == .headerOnly, "One 16:9 image is both places: it isn't kept")
        #expect(made.keptPlace == nil)
        #expect(made.artwork.map(\.fileID) == ["h-new", "h-new-de"])

        var alone = Self.newHeader
        alone.keepOtherPlace(from: nil, making: .headerOnly)
        #expect(alone == Self.newHeader)

        var both = Self.newHeader
        both.artworkSize = .headerAndSearch
        both.keepOtherPlace(from: Self.earlier, making: .headerAndSearch)
        #expect(both.keptPlace == nil, "A run that makes both keeps nothing")
    }

    /// Made alone, the header joins the search image that's on App Store
    /// Connect, which stays pushed.
    @Test func aHeaderOnlyRunSavesTheSearchImageMadeBefore() async throws {
        let center = AutopilotTestFixtures.center()
        let services = AutopilotTestFixtures.services(center)
        let context = AutopilotTestFixtures.context(services)
        var document = try await services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        document.extras = Self.earlier
        document.extras?.pushedChecksums = ["search-en-US": "s-old"]
        try await services.saveDocument(document, for: AutopilotTestFixtures.app)

        var start = StudioDebugRuns.run(.localize)
        start.plan.localeCodes = ["en-US"]
        start.plan.runChoice.makesScreenshots = false
        start.plan.alsoMakes = AutopilotExtras(makesArtwork: true, artworkSize: .headerOnly)
        center.install(start)
        await center.makeExtras(StudioDebugRuns.appID, context: context)

        let extras = try #require(try await services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS).extras)
        #expect(extras.artworkSize == .headerAndSearch)
        #expect(extras.artwork.filter { $0.kind == .header }.map(\.locale) == ["en-US"])
        #expect(extras.artwork.first { $0.kind == .header }?.fileID != "h-old", "The header is this run's")
        #expect(extras.artwork.filter { $0.kind == .search }.map(\.fileID) == ["s-old", "s-old-de"])
        #expect(extras.keptPlace?.directionName == "Quiet Indigo")
        #expect(extras.pushedChecksums == ["search-en-US": "s-old"], "Nothing new to push for search")
    }

    // MARK: - The preview

    @Test func thePreviewShowsOnlyTheImageMade() async throws {
        let run = StudioDebugExtras.run(.ready, size: .headerOnly, languages: .primary)
        var document = ScreenshotsDebugDocuments.standard
        document.extras = StudioDebugExtras.extras(for: run)
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run), document: document)
        model.studio.choice = .new
        let preview = try #require(model.studio.extrasPreview)
        #expect(preview.header?.kind == .header)
        #expect(preview.search == nil, "Search results show the screenshots")
        model.studio.openArtwork(at: 0)
        #expect(model.studio.viewer?.items.map(\.id) == ["artwork.header"])
    }

    @Test func thePreviewDrawsTheKeptPlaceAsItWasMade() async throws {
        let run = StudioDebugExtras.run(.ready, size: .headerOnly, languages: .primary)
        var made = Self.newHeader
        made.keepOtherPlace(from: Self.earlier, making: .headerOnly)
        var document = ScreenshotsDebugDocuments.standard
        document.extras = made
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run), document: document)
        model.studio.choice = .new
        let preview = try #require(model.studio.extrasPreview)
        let header = try #require(preview.header)
        #expect(header.page == "<p>new header</p>")
        #expect(!header.isMotion)
        let search = try #require(preview.search)
        #expect(search.kind == .search)
        #expect(search.page == "<p>old search</p>")
        #expect(search.isMotion, "Kept as a loop")
        #expect(search.shows == .ui)
        #expect(search.template == Self.earlierLook)
        model.studio.openArtwork(at: 1)
        #expect(model.studio.viewer?.items.map(\.id) == ["artwork.header", "artwork.search"])
    }
}
#endif
