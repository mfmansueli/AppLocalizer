//
//  LiveScreenshotsServicesTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The live screenshot and App Preview sets read from canned App Store
/// Connect pages; nothing reaches Apple.
@MainActor
@Suite("LiveScreenshotsServices")
struct LiveScreenshotsServicesTests {
    private typealias Canned = ScreenshotsCannedResponses

    private let app = StoreApp(id: "6450000001", name: "Lumen Journal", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")

    private func services(_ transport: FakeHTTPTransport) -> LiveScreenshotsServices {
        LiveScreenshotsServices(
            client: AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport),
            store: InMemoryScreenshotsDocumentStore(),
            renderCacheDirectory: nil
        )
    }

    @Test func setsAreReadPerLocaleWithTheirScreenshotsInOrder() async throws {
        let transport = FakeHTTPTransport([
            Canned.page(
                [
                    Canned.screenshotSet("de-iphone", displayType: "APP_IPHONE_67", screenshots: ["d2", "d1"]),
                    Canned.screenshotSet("de-small", displayType: "APP_IPHONE_61", screenshots: ["d3"]),
                ],
                included: [Canned.screenshot("d1", fileName: "one.png", checksum: "c1"), Canned.screenshot("d2", fileName: "two.png", checksum: "c2")]
            ),
            Canned.page([]),
            Canned.page(
                [Canned.screenshotSet("en-ipad", displayType: "APP_IPAD_PRO_3GEN_129", screenshots: ["e1"])],
                included: [Canned.screenshot("e1", fileName: "ipad.png", checksum: "c3")]
            ),
            Canned.page(
                [Canned.previewSet("en-previews", previewType: "IPHONE_67", previews: ["p1"])],
                included: [Canned.preview("p1", timeCode: "00:00:05:00")]
            ),
        ])
        let live = try await services(transport).liveScreenshots(for: app, localizations: [.englishUS: "vl-en", .german: "vl-de"])

        #expect(transport.requests.map { $0.url?.path() } == [
            "/v1/appStoreVersionLocalizations/vl-de/appScreenshotSets",
            "/v1/appStoreVersionLocalizations/vl-de/appPreviewSets",
            "/v1/appStoreVersionLocalizations/vl-en/appScreenshotSets",
            "/v1/appStoreVersionLocalizations/vl-en/appPreviewSets",
        ])
        let german = try #require(live.set(locale: "de-DE", displayType: .iPhone))
        #expect(german.screenshots.map(\.id) == ["d2", "d1"])
        #expect(german.screenshots.first?.checksum == "c2")
        #expect(live.screenshotSets.count == 2)
        #expect(live.set(locale: "en-US", displayType: .iPad)?.screenshots.first?.pixelSize == PixelSize(width: 1320, height: 2868))
        let previews = try #require(live.previews(locale: "en-US", displayType: .iPhone))
        #expect(previews.previewCount == 1)
        #expect(previews.posterFrameTimeCode == "00:00:05:00")
        #expect(previews.durationTitle == nil)
    }

    @Test func theScreenshotRequestIncludesTheScreenshots() async throws {
        let transport = FakeHTTPTransport([Canned.page([]), Canned.page([])])
        _ = try await services(transport).liveScreenshots(for: app, localizations: [.englishUS: "vl-en"])
        let query = transport.requests.first?.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        #expect(query.contains(URLQueryItem(name: "include", value: "appScreenshots")))
    }

    @Test func pagesAreFollowed() async throws {
        let transport = FakeHTTPTransport([
            Canned.page(
                [Canned.screenshotSet("one", displayType: "APP_IPHONE_67", screenshots: [])],
                next: "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/vl-en/appScreenshotSets?cursor=2"
            ),
            Canned.page([Canned.screenshotSet("two", displayType: "APP_IPAD_PRO_3GEN_129", screenshots: [])]),
            Canned.page([]),
        ])
        let live = try await services(transport).liveScreenshots(for: app, localizations: [.englishUS: "vl-en"])
        #expect(live.screenshotSets.map(\.id) == ["one", "two"])
        #expect(transport.requests.count == 3)
    }

    @Test func aRateLimitIsReported() async {
        let transport = FakeHTTPTransport([CannedHTTPResponse(statusCode: 429, body: "{}")])
        await #expect(throws: AppStoreConnectError.rateLimited) {
            try await services(transport).liveScreenshots(for: app, localizations: [.englishUS: "vl-en"])
        }
    }

    @Test func liveImageURLsFillTheTemplate() {
        let shot = LiveScreenshot(
            id: "s", fileName: "a.png", checksum: nil, pixelSize: PixelSize(width: 1320, height: 2868),
            imageURLTemplate: "https://example.invalid/s/{w}x{h}bb.{f}"
        )
        #expect(shot.imageURL(width: 184)?.absoluteString == "https://example.invalid/s/184x400bb.png")
    }

    @Test func theDocumentStartsEmptyAndIsSaved() async throws {
        let services = services(FakeHTTPTransport([]))
        let empty = try await services.document(for: app, primaryLocale: .englishUS)
        #expect(empty.template == nil)
        #expect(empty.scope.primary == "en-US")
        var document = empty
        document.scope.set("de-DE", included: true)
        try await services.save(document, for: app)
        #expect(try await services.document(for: app, primaryLocale: .englishUS).scope.contains("de-DE"))
    }
}
