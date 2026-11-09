//
//  StorePageVersion.swift
//  AppLocalizer
//

import Foundation

/// An App Store version in the version picker: App Store Connect's
/// resource ID plus what the editing model needs (`ListingVersion`).
struct StorePageVersion: Identifiable, Hashable, Sendable {
    /// The `appStoreVersions` resource ID.
    let id: String
    let listingVersion: ListingVersion
    /// App Store Connect's platform, e.g. `IOS` or `MAC_OS`.
    var platform: String?
    var createdDate: Date?

    var versionString: String { listingVersion.versionString }
    var state: ListingVersionState { listingVersion.state }
    var isEditable: Bool { listingVersion.isEditable }

    /// Picks the versions the picker lists out of everything App Store
    /// Connect returned: states the Store Page knows (replaced and removed
    /// versions are left out), newest first, at most one live one per
    /// platform.
    static func pickerVersions(from versions: [StorePageVersion]) -> [StorePageVersion] {
        let newestFirst = versions.sorted { ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast) }
        var livePlatforms: Set<String?> = []
        return newestFirst.filter { version in
            guard version.state.isLive else { return true }
            return livePlatforms.insert(version.platform).inserted
        }
    }

    /// The version the Store Page opens on: the newest editable one, else the
    /// newest live one, else the newest of any state. An app with an iOS
    /// version opens on it, even when its macOS version is newer: iPhone and
    /// iPad screenshots can only go in iOS localizations (App Store Connect
    /// refuses them elsewhere with "Display Type Not Allowed!").
    static func preferred(in versions: [StorePageVersion]) -> StorePageVersion? {
        let iOS = versions.filter { $0.platform == iOSPlatform }
        let candidates = iOS.isEmpty ? versions : iOS
        return candidates.first(where: \.isEditable) ?? candidates.first(where: \.state.isLive) ?? candidates.first
    }

    private static let iOSPlatform = "IOS"

    /// "macOS"; nil for a platform without a name here.
    var platformTitle: String? {
        switch platform {
        case Self.iOSPlatform: "iOS"
        case "MAC_OS": "macOS"
        case "VISION_OS": "visionOS"
        case "TV_OS": "tvOS"
        default: nil
        }
    }

    /// The platform when it's not iOS, for the review sheet's heading: an
    /// app's iOS and macOS "1.0" aren't the same page.
    var otherPlatformTitle: String? {
        platform == Self.iOSPlatform ? nil : platformTitle
    }

    /// The picker's row, with the platform when `versions` have several:
    /// "1.0 · Prepare for Submission · macOS".
    func pickerTitle(among versions: [StorePageVersion]) -> String {
        withPlatform(listingVersion.pickerTitle, among: versions)
    }

    /// "Version 1.0 · Prepare for Submission · macOS", likewise.
    func title(among versions: [StorePageVersion]) -> String {
        withPlatform(listingVersion.title, among: versions)
    }

    private func withPlatform(_ text: String, among versions: [StorePageVersion]) -> String {
        guard Set(versions.map(\.platform)).count > 1, let platformTitle else { return text }
        return "\(text) · \(platformTitle)"
    }

    /// Whether `platform` has only this one version among `platforms`: a
    /// first version, which has no What's New. Each platform has its own.
    static func isOnlyVersion(of platform: String?, among platforms: [String?]) -> Bool {
        platforms.count { $0 == platform } == 1
    }
}
