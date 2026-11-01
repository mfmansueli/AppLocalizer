//
//  AppStoreConnectClient+Builds.swift
//  AppLocalizer
//

import Foundation

// What's inside the build attached to a version: App Store Connect lists
// the icons it extracted from the binary, one per platform the build
// carries. The latest build's icon is the app's icon in the library.
extension AppStoreConnectClient {
    /// The types of the icons in a build (`GET /v1/builds/{id}/icons`).
    func buildIconTypes(buildID: String) async throws -> [String] {
        let query = [URLQueryItem(name: "fields[buildIcons]", value: "iconType"), URLQueryItem(name: "limit", value: "50")]
        let icons: [AppStoreConnectResource<BuildIconAttributes>] = try await allPages(of: "/v1/builds/\(buildID)/icons", query: query)
        return icons.compactMap(\.attributes.iconType)
    }

    /// Whether the build attached to the version has an Apple Watch app;
    /// false when no build is attached.
    func versionHasWatchApp(versionID: String) async throws -> Bool {
        guard let build = try await versionBuild(versionID: versionID) else { return false }
        return try await buildIconTypes(buildID: build.id).contains(BuildIconAttributes.watchAppStore)
    }

    /// The app's icon, `side` pixels square, from its most recently
    /// uploaded build that has one (`GET /v1/builds?filter[app]=…`). Nil
    /// before App Store Connect has processed a build.
    func appIconURL(appID: String, side: Int = 256) async throws -> URL? {
        let page: BuildsPage = try await get(url("/v1/builds", query: [
            URLQueryItem(name: "filter[app]", value: appID),
            URLQueryItem(name: "sort", value: "-uploadedDate"),
            URLQueryItem(name: "fields[builds]", value: "iconAssetToken"),
            URLQueryItem(name: "limit", value: "5"),
        ]))
        return page.data.lazy.compactMap { $0.attributes?.iconAssetToken?.url(side: side) }.first
    }

    /// Just the builds' icons; a build still processing may come without.
    private struct BuildsPage: Decodable {
        var data: [BuildsPageBuild]
    }

    private struct BuildsPageBuild: Decodable {
        var attributes: BuildIconAssetAttributes?
    }
}
