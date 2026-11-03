//
//  ProductPageTestFixtures.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// A header test in English and German, its variants as real files in a
/// folder of its own (the export copies them), and an environment against
/// fakes.
@MainActor
enum ProductPageTestFixtures {
    static let appID = "app-1"
    static let headerSize = PixelSize(width: 3840, height: 1646)

    /// A new folder with each language's control and treatment image.
    static func folder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "ProductPageTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for locale in ["en-US", "de-DE"] {
            try Data("control \(locale)".utf8).write(to: folder.appending(path: "header-control-\(locale).png"))
            try Data("outcome \(locale)".utf8).write(to: folder.appending(path: "header-outcome-\(locale).png"))
        }
        return folder
    }

    static func request(
        in folder: URL, placement: ProductPageTestPlacement = .header, locales: [String] = ["en-US", "de-DE"],
        size: PixelSize = headerSize, startsTest: Bool = false, controls: Bool = true
    ) -> ProductPageTestRequest {
        ProductPageTestRequest(
            appID: appID, appName: "Lumen", placement: placement, testName: "Header: Interface vs Outcome",
            locales: locales.map { locale in
                ProductPageTestLocale(
                    locale: locale, treatmentFile: folder.appending(path: "header-outcome-\(locale).png"), treatmentPixelSize: size,
                    controlFile: controls ? folder.appending(path: "header-control-\(locale).png") : nil
                )
            },
            startsTest: startsTest, exportFolder: folder.appending(path: "Export")
        )
    }

    static func environment(
        _ tester: FakeProductPageTesting, library: FakeAssetLibrary = FakeAssetLibrary(), placesThroughAPI: Bool = true
    ) -> ProductPageTestEnvironment {
        let clock = ScreenshotPushTestClock()
        return ProductPageTestEnvironment(
            tester: tester, library: library, rate: RequestRateTracker(now: { clock.now }), placesThroughAPI: placesThroughAPI,
            fileData: { url in Data("bytes of \(url.lastPathComponent)".utf8) },
            now: { clock.now }, sleep: { clock.advance(by: $0) },
            pollInterval: .seconds(1), longestPollInterval: .seconds(1), processingTimeout: .seconds(60)
        )
    }

    /// Runs the test to the end.
    static func run(_ request: ProductPageTestRequest, environment: ProductPageTestEnvironment) async -> ProductPageTestRun {
        let run = ProductPageTestRun(request: request, environment: environment)
        run.start()
        await run.waitUntilFinished()
        return run
    }
}
