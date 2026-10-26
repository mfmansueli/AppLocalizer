//
//  PushTransport.swift
//  AppLocalizer
//

import Foundation

/// Where Review & Push sends writes and conflict checks. The API client is
/// the real one; DEBUG scenes and tests simulate App Store Connect.
protocol PushTransport: Sendable {
    func send(_ request: PushRequest) async throws -> AppStoreConnectResponse
    func fetch(_ path: String) async throws -> AppStoreConnectResponse
}

extension AppStoreConnectClient: PushTransport {}
