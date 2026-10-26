//
//  AppStoreConnectClient+StorePageScreenshots.swift
//  AppLocalizer
//

import Foundation

extension AppStoreConnectClient {
    /// One version localization's screenshot sets, each with the
    /// screenshots it links to, following `links.next`
    /// (`GET /v1/appStoreVersionLocalizations/{id}/appScreenshotSets`).
    func appScreenshotSets(localizationID: String) async throws -> [AppScreenshotSetPage.ScreenshotSet] {
        var next: URL? = url("/v1/appStoreVersionLocalizations/\(localizationID)/appScreenshotSets", query: [
            URLQueryItem(name: "include", value: "appScreenshots"),
            URLQueryItem(name: "limit", value: "50"),
        ])
        var sets: [AppScreenshotSetPage.ScreenshotSet] = []
        while let pageURL = next {
            let page: AppScreenshotSetPage = try await get(pageURL)
            sets += page.data
            next = page.links?.next
        }
        return sets
    }
}
