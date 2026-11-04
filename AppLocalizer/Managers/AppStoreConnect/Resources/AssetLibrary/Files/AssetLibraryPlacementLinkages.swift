//
//  AssetLibraryPlacementLinkages.swift
//  AppLocalizer
//

import Foundation

/// `GET …/relationships/placements`: the placements' IDs, and in `meta`
/// how many there are in all.
struct AssetLibraryPlacementLinkages: Decodable {
    struct Linkage: Decodable {
        var id: String
    }

    struct Paging: Decodable {
        var total: Int?
    }

    struct Meta: Decodable {
        var paging: Paging?
    }

    var data: [Linkage]
    var meta: Meta?
}
