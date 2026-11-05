//
//  InAppTextVersionAttributes.swift
//  AppLocalizer
//

import Foundation

/// A `subscriptionGroupVersions`, `subscriptionVersions` or
/// `inAppPurchaseVersions` resource (App Store Connect API 4.4.1): a
/// numbered copy of a group's, subscription's or purchase's texts for App
/// Review. Only one that hasn't been submitted, or was rejected, takes
/// edits (`InAppTextsContent.editableVersionStates`).
struct InAppTextVersionAttributes: Decodable, Hashable, Sendable {
    /// 1, 2, … in the order they were made.
    var version: Int?
    /// `PREPARE_FOR_SUBMISSION`, `READY_FOR_REVIEW`, `APPROVED`, …
    var state: String?
}
