//
//  AppStoreConnectPage.swift
//  AppLocalizer
//

import Foundation

/// One page of a JSON:API collection response (`GET /v1/apps`, …).
/// `links.next` is set while more pages follow.
struct AppStoreConnectPage<Attributes: Decodable & Sendable>: Decodable, Sendable {
    var data: [AppStoreConnectResource<Attributes>]
    var links: AppStoreConnectPageLinks?
}
