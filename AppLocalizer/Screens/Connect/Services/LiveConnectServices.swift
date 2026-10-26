//
//  LiveConnectServices.swift
//  AppLocalizer
//

import Foundation

/// The real `ConnectServices`: one `GET /v1/apps?limit=1` with the key.
@MainActor
struct LiveConnectServices: ConnectServices {
    func verify(_ credentials: AppStoreConnectCredentials) async throws {
        try await AppStoreConnectClient(credentials: credentials).verifyAccess()
    }
}
