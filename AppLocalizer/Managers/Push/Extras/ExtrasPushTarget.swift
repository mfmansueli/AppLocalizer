//
//  ExtrasPushTarget.swift
//  AppLocalizer
//

import Foundation

/// One slot an extra is placed in: a placement type in a placement group,
/// e.g. `PRODUCT_PAGE_HEADER_ASSET` in an iPhone profile group.
struct ExtrasPushTarget: Hashable, Sendable {
    var placementType: String
    var placementGroup: String
}
