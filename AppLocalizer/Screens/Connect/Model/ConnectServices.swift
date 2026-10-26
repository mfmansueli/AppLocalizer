//
//  ConnectServices.swift
//  AppLocalizer
//

import Foundation

/// What the connect screen needs from outside itself. `LiveConnectServices`
/// asks App Store Connect; tests and DEBUG scenes use fakes.
@MainActor
protocol ConnectServices {
    /// Makes one signed request with the key; throws
    /// `AppStoreConnectError.unauthorized` (or a network error) if it fails.
    func verify(_ credentials: AppStoreConnectCredentials) async throws
}
