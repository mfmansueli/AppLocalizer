//
//  AccessibilityContentLoader.swift
//  AppLocalizer
//

import Foundation

/// Reads the Accessibility page from App Store Connect: the app's
/// declarations (replaced ones left out), its versions (which platforms it
/// has, and which have a live version) and the accessibility URL.
struct AccessibilityContentLoader: Sendable {
    let client: AppStoreConnectClient

    func content(for app: StoreApp) async throws -> AccessibilityContent {
        let resources = try await client.accessibilityDeclarations(appID: app.id)
        let declarations = resources.compactMap(Self.declaration)
        let versions = try await client.appStoreVersionReleases(appID: app.id)
        let appResource = try await client.appInformationApp(appID: app.id)

        let live = versions.filter { AppInformationContentLoader.state(of: $0.attributes)?.isLive == true }
        let livePlatforms = Set(live.compactMap(\.attributes.platform))
        let families = AccessibilityContent.families(platforms: versions.map(\.attributes.platform), declared: declarations.map(\.family))
        let upcoming = versions
            .filter { AppInformationContentLoader.state(of: $0.attributes)?.isEditable == true }
            .max { ($0.attributes.createdDate ?? "") < ($1.attributes.createdDate ?? "") }
        return AccessibilityContent(
            families: families,
            // Every family of a live platform, so Apple Watch declared from
            // Other Devices can publish with the iOS app's live version.
            liveFamilies: Set(DeviceFamily.allCases.filter { livePlatforms.contains($0.platform) }),
            declarations: declarations,
            accessibilityURL: appResource?.attributes.accessibilityUrl ?? "",
            upcomingVersion: upcoming?.attributes.versionString
        )
    }

    /// A draft or published declaration of a family this app knows.
    static func declaration(_ resource: AppStoreConnectResource<AccessibilityDeclarationAttributes>) -> AccessibilityDeclaration? {
        guard let family = resource.attributes.deviceFamily.flatMap(DeviceFamily.init(rawValue:)),
              let state = resource.attributes.state.flatMap(AccessibilityDeclarationState.init(rawValue:)),
              state != .replaced
        else { return nil }
        return AccessibilityDeclaration(id: resource.id, family: family, state: state, answer: AccessibilityAnswer(supports: resource.attributes.supports))
    }
}
