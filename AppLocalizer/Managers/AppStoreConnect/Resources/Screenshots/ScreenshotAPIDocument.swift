//
//  ScreenshotAPIDocument.swift
//  AppLocalizer
//

import Foundation

/// One page of sets with their items included:
/// `GET /v1/appStoreVersionLocalizations/{id}/appScreenshotSets?include=appScreenshots`
/// or `…/appPreviewSets?include=appPreviews`.
struct ScreenshotAPIDocument<SetAttributes: Decodable & Sendable, ItemAttributes: Decodable & Sendable>: Decodable, Sendable {
    var data: [ScreenshotAPIResource<SetAttributes>]
    var included: [ScreenshotAPIResource<ItemAttributes>]?
    var links: AppStoreConnectPageLinks?

    /// The included items `set` links to under `relationship`, in the set's
    /// order.
    func items(of set: ScreenshotAPIResource<SetAttributes>, relationship: String) -> [ScreenshotAPIResource<ItemAttributes>] {
        let byID = Dictionary((included ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return set.related(relationship).compactMap { byID[$0.id] }
    }
}
