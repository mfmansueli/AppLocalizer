//
//  AppStoreConnectClient+Builds.swift
//  AppLocalizer
//

import Foundation

// What's inside the build attached to a version: App Store Connect lists
// the icons it extracted from the binary, one per platform the build
// carries.
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
}
