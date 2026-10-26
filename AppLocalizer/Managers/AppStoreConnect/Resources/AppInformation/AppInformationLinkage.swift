//
//  AppInformationLinkage.swift
//  AppLocalizer
//

import Foundation

/// A to-one relationship as App Store Connect returns it, e.g. an app
/// info's `primaryCategory` (`{"data": {"type": "appCategories", "id":
/// "LIFESTYLE"}}`) or a version's `build`. `data` is nil when nothing is
/// related, or when the response didn't include the linkage.
struct AppInformationLinkage: Decodable, Sendable {
    struct Identifier: Decodable, Sendable {
        var type: String
        var id: String
    }

    var data: Identifier?
}
