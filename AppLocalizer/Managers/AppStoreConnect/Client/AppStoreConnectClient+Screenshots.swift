//
//  AppStoreConnectClient+Screenshots.swift
//  AppLocalizer
//

import Foundation

extension AppStoreConnectClient {
    /// One version localization's screenshot sets for the display types
    /// templates render, with their screenshots in App Store order
    /// (`GET /v1/appStoreVersionLocalizations/{id}/appScreenshotSets`).
    func liveScreenshotSets(localizationID: String, locale: String) async throws -> [LiveScreenshotSet] {
        var next: URL? = url("/v1/appStoreVersionLocalizations/\(localizationID)/appScreenshotSets", query: [
            URLQueryItem(name: "include", value: "appScreenshots"),
            URLQueryItem(name: "fields[appScreenshotSets]", value: "screenshotDisplayType,appScreenshots"),
            URLQueryItem(name: "fields[appScreenshots]", value: "fileName,fileSize,sourceFileChecksum,imageAsset"),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "limit[appScreenshots]", value: "10"),
        ])
        var sets: [LiveScreenshotSet] = []
        while let pageURL = next {
            let page: ScreenshotAPIDocument<AppScreenshotSetAttributes, AppScreenshotAttributes> = try await get(pageURL)
            for set in page.data {
                guard let type = set.attributes?.screenshotDisplayType, let display = ScreenshotDisplayType(apiValue: type) else { continue }
                let screenshots = page.items(of: set, relationship: "appScreenshots").map(Self.liveScreenshot)
                sets.append(LiveScreenshotSet(id: set.id, locale: locale, displayType: display, screenshots: screenshots))
            }
            next = page.links?.next
        }
        return sets
    }

    /// One version localization's App Preview sets
    /// (`GET /v1/appStoreVersionLocalizations/{id}/appPreviewSets`).
    func livePreviewSets(localizationID: String, locale: String) async throws -> [LiveAppPreviewSet] {
        var next: URL? = url("/v1/appStoreVersionLocalizations/\(localizationID)/appPreviewSets", query: [
            URLQueryItem(name: "include", value: "appPreviews"),
            URLQueryItem(name: "fields[appPreviewSets]", value: "previewType,appPreviews"),
            URLQueryItem(name: "fields[appPreviews]", value: "fileName,previewFrameTimeCode,mimeType"),
            URLQueryItem(name: "limit", value: "50"),
        ])
        var sets: [LiveAppPreviewSet] = []
        while let pageURL = next {
            let page: ScreenshotAPIDocument<AppPreviewSetAttributes, AppPreviewAttributes> = try await get(pageURL)
            for set in page.data {
                guard let type = set.attributes?.previewType,
                      let display = ScreenshotDisplayType.allCases.first(where: { $0.previewType == type }) else { continue }
                let previews = page.items(of: set, relationship: "appPreviews")
                sets.append(LiveAppPreviewSet(
                    id: set.id, locale: locale, displayType: display, previewCount: set.related("appPreviews").count,
                    posterFrameTimeCode: previews.first?.attributes?.previewFrameTimeCode, durationSeconds: nil
                ))
            }
            next = page.links?.next
        }
        return sets
    }

    private static func liveScreenshot(_ resource: ScreenshotAPIResource<AppScreenshotAttributes>) -> LiveScreenshot {
        let asset = resource.attributes?.imageAsset
        let size = asset.flatMap { asset in asset.width.flatMap { width in asset.height.map { PixelSize(width: width, height: $0) } } }
        return LiveScreenshot(
            id: resource.id, fileName: resource.attributes?.fileName ?? "",
            checksum: resource.attributes?.sourceFileChecksum, pixelSize: size, imageURLTemplate: asset?.templateUrl
        )
    }
}
