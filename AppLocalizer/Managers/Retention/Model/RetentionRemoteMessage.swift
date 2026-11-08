//
//  RetentionRemoteMessage.swift
//  AppLocalizer
//

import Foundation

/// A retention message as App Store Connect has it: the message, the
/// subscriptions that show it, and the version AppLocalizer reads and
/// writes (one still being prepared or reviewed, else the live one), with
/// its localizations and image placement.
struct RetentionRemoteMessage: Hashable, Codable, Sendable {
    var messageID: String
    var referenceName: String
    var subscriptionIDs: [String]
    var versionID: String?
    var versionState: RetentionVersionState?
    /// Whether some version of it is approved, so subscribers see one now.
    var hasLiveVersion = false
    /// By locale code.
    var localizations: [String: RetentionRemoteLocalization] = [:]
    var placementID: String?
    /// The `appAssetLibraryImages` the placement shows.
    var imageID: String?

    var texts: [String: RetentionText] {
        localizations.mapValues(\.text)
    }

    /// The pill before anything is queued.
    /// A version still being prepared over an approved one: subscribers
    /// see the approved one, so it's Live.
    var status: RetentionMessageStatus {
        let status = versionState?.status ?? .draft
        return status == .draft && hasLiveVersion ? .live : status
    }
}
