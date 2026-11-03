//
//  ExtrasPushFixtures.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// German extras for one app, the environment a test push runs in, and a
/// way to run one to the end.
@MainActor
enum ExtrasPushFixtures {
    static let appID = "app-1"
    static let localizationID = "loc-de"
    static let headerGroup = AssetLibraryRefDataSample.headerGroup
    static let searchGroup = AssetLibraryRefDataSample.searchGroup
    static let iPhoneGroup = AssetLibraryRefDataSample.iPhoneGroup

    static func header(size: PixelSize = PixelSize(width: 3840, height: 1646)) -> ExtrasPushItem {
        item(
            id: "de-header", title: "German · Header 21:9", kind: .artwork(placementTypes: [ExtrasPushKind.productPageHeader]),
            file: "de-DE-header.png", size: size
        )
    }

    /// One 16:9 image for the header and search results.
    static func wide() -> ExtrasPushItem {
        item(
            id: "de-wide", title: "German · Header and search 16:9",
            kind: .artwork(placementTypes: [ExtrasPushKind.productPageHeader, ExtrasPushKind.searchResults]),
            file: "de-DE-wide.png", size: PixelSize(width: 5244, height: 2950)
        )
    }

    static func preview(replacing replaced: [String] = []) -> ExtrasPushItem {
        var preview = item(
            id: "de-preview", title: "German · App Preview", kind: .appPreview(posterTimeCode: "00:00:05:00"),
            file: "de-DE-preview.mov", size: PixelSize(width: 886, height: 1920)
        )
        preview.replacesPlacementIDs = replaced
        return preview
    }

    /// What the fake file of `item` holds.
    static func data(for item: ExtrasPushItem) -> Data {
        Data("bytes of \(item.fileURL.lastPathComponent)".utf8)
    }

    /// A placement the localization shows already.
    static func live(_ id: String, _ placementType: String, group: String, media: AssetLibraryMedia = .image) -> AssetLibraryPlacement {
        AssetLibraryPlacement(id: id, placementType: placementType, placementGroup: group, state: "PARENT_APPROVED", asset: AssetLibraryAsset(id: "asset-\(id)", media: media))
    }

    static func livePreviews(_ ids: [String]) -> [String: [AssetLibraryPlacement]] {
        [localizationID: ids.map { live($0, ExtrasPushKind.appPreviewPlacement, group: iPhoneGroup, media: .video) }]
    }

    static func environment(
        _ library: FakeAssetLibrary, clock: ScreenshotPushTestClock = ScreenshotPushTestClock(), processingTimeout: Duration = .seconds(60)
    ) -> ExtrasPushEnvironment {
        ExtrasPushEnvironment(
            library: library,
            rate: RequestRateTracker(now: { clock.now }),
            fileData: { url in Data("bytes of \(url.lastPathComponent)".utf8) },
            now: { clock.now },
            sleep: { clock.advance(by: $0) },
            pollInterval: .seconds(1),
            longestPollInterval: .seconds(1),
            processingTimeout: processingTimeout
        )
    }

    /// Runs a push of `items` to the end.
    static func push(_ items: [ExtrasPushItem], environment: ExtrasPushEnvironment) async -> ExtrasPushRun {
        let run = ExtrasPushRun(items: items, environment: environment)
        run.start()
        await run.waitUntilFinished()
        return run
    }

    private static func item(id: String, title: String, kind: ExtrasPushKind, file: String, size: PixelSize) -> ExtrasPushItem {
        ExtrasPushItem(
            id: id, appID: appID, title: title, localizationID: localizationID, kind: kind, fileName: file, pixelSize: size,
            referenceName: "Autopilot · \(title)", fileURL: URL(fileURLWithPath: "/tmp/extras/\(file)")
        )
    }
}
