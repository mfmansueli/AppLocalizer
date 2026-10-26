//
//  AppInfoRatingAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `appInfos` attributes App Information reads: the age rating App Store
/// Connect shows now (`FOUR_PLUS` … `EIGHTEEN_PLUS`, `UNRATED`) and the
/// state that says whether this is the app info being prepared.
struct AppInfoRatingAttributes: Decodable, Sendable {
    var appStoreAgeRating: String?
    var state: String?
    var appStoreState: String?
}
