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
}
