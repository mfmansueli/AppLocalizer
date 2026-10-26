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
    /// versions are left out), newest first, at most one live one.
    static func pickerVersions(from versions: [StorePageVersion]) -> [StorePageVersion] {
        let newestFirst = versions.sorted { ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast) }
        var sawLive = false
        return newestFirst.filter { version in
            guard version.state.isLive else { return true }
            defer { sawLive = true }
            return !sawLive
        }
    }

    /// The version the Store Page opens on: the newest editable one, else the
    /// newest live one, else the newest of any state.
    static func preferred(in versions: [StorePageVersion]) -> StorePageVersion? {
        versions.first(where: \.isEditable) ?? versions.first(where: \.state.isLive) ?? versions.first
    }
}
