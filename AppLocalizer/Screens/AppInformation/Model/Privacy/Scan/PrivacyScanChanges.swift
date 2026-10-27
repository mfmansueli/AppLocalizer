//
//  PrivacyScanChanges.swift
//  AppLocalizer
//

import Foundation

/// What a later scan changed since the one before it: SDKs added or
/// removed, data types with a new or different suggestion, and how many
/// answers stayed the same.
struct PrivacyScanChanges: Hashable, Codable, Sendable {
    /// When the scan before it ran.
    var since: Date
    var addedSDKs: [PrivacySDK] = []
    var removedSDKs: [PrivacySDK] = []
    var changedTypes: [PrivacyDataType] = []
    var unchangedCount = 0

    var isEmpty: Bool {
        addedSDKs.isEmpty && removedSDKs.isEmpty && changedTypes.isEmpty
    }
}
