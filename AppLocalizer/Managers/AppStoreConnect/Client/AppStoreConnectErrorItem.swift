//
//  AppStoreConnectErrorItem.swift
//  AppLocalizer
//

import Foundation

/// One entry of an `AppStoreConnectErrorResponse`, e.g. code
/// `NOT_AUTHORIZED` with a human-readable `detail`.
struct AppStoreConnectErrorItem: Decodable, Sendable {
    var status: String?
    var code: String?
    var title: String?
    var detail: String?
}
