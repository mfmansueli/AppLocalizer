//
//  AppStoreConnectResource.swift
//  AppLocalizer
//

import Foundation

/// A JSON:API resource object: `{ "type": "apps", "id": "…", "attributes": {…} }`.
struct AppStoreConnectResource<Attributes: Decodable & Sendable>: Decodable, Sendable {
    var type: String
    var id: String
    var attributes: Attributes
}
