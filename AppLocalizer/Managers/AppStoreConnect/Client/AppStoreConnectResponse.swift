//
//  AppStoreConnectResponse.swift
//  AppLocalizer
//

import Foundation

/// A successful response's body and the quota left after it.
struct AppStoreConnectResponse: Sendable {
    var data: Data
    var rateLimit: AppStoreConnectRateLimit?
}
