//
//  RemoteConflict.swift
//  AppLocalizer
//

import Foundation

/// A value that changed in App Store Connect after it was fetched, found by
/// the change's `ConflictCheck` just before pushing. The change stays pending
/// until the person keeps theirs or takes App Store Connect's.
struct RemoteConflict: Hashable, Codable, Sendable {
    /// What App Store Connect has now, as read by the check; nil when empty.
    var remoteRawValue: String?
    /// The same value as the review row shows it, e.g. "R$ 199,90".
    var remoteDisplayValue: String
}
