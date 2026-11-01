//
//  AppIconImagesTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Synchronization
import Testing
@testable import AppLocalizer

/// Icons are downloaded once and drawn without their margin; a failed
/// download is tried again.
@MainActor
@Suite("App icon images")
struct AppIconImagesTests {
    private let url = URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Purple/AppIcon.png/256x256bb.png")!

    /// Answers with a Mac-like icon (80 px of artwork in 100), or fails
    /// while `fails` is set; counts the downloads.
    private final class Server: Sendable {
        let downloads = Mutex(0)
        let fails = Mutex(false)
        let png = ScreenshotPNG.data(AppIconMarginTests.image(filling: [(CGRect(x: 10, y: 10, width: 80, height: 80), 1)]))!

        func fetch(_: URL) throws -> Data {
            downloads.withLock { $0 += 1 }
            if fails.withLock({ $0 }) { throw URLError(.notConnectedToInternet) }
            return png
        }
    }

    @Test func anIconIsDownloadedOnceWithoutItsMargin() async throws {
        let server = Server()
        let images = AppIconImages { try server.fetch($0) }
        #expect(images.cached(url) == nil)

        let image = try #require(await images.image(for: url))
        #expect(image.width == 80)
        #expect(images.cached(url) === image)
        #expect(await images.image(for: url) === image)
        #expect(server.downloads.withLock { $0 } == 1)
    }

    @Test func aFailedDownloadIsTriedAgain() async {
        let server = Server()
        server.fails.withLock { $0 = true }
        let images = AppIconImages { try server.fetch($0) }
        #expect(await images.image(for: url) == nil)
        #expect(images.cached(url) == nil)

        server.fails.withLock { $0 = false }
        #expect(await images.image(for: url) != nil)
        #expect(server.downloads.withLock { $0 } == 2)
    }
}
