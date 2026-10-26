//
//  AppStoreConnectErrorResponse.swift
//  AppLocalizer
//

import Foundation

/// The JSON:API `errors` document App Store Connect returns with 4xx/5xx.
struct AppStoreConnectErrorResponse: Decodable, Sendable {
    var errors: [AppStoreConnectErrorItem]
}
