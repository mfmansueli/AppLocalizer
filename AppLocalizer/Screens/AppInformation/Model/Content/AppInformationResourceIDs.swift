//
//  AppInformationResourceIDs.swift
//  AppLocalizer
//

import Foundation

/// The App Store Connect resources App Information writes to.
struct AppInformationResourceIDs: Hashable, Sendable {
    /// The `apps` resource: content rights and the accessibility URL.
    var appID: StoreApp.ID
    /// The app info being prepared (else the live one): categories.
    var appInfoID: String
    /// Its `ageRatingDeclarations` resource.
    var ageRatingDeclarationID: String?
    /// The shown version: copyright, release and App Review.
    var versionID: String?
    /// The version's `appStoreReviewDetails`; nil until it has one.
    var reviewDetailID: String?
}
