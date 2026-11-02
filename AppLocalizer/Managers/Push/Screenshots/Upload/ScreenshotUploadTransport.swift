//
//  ScreenshotUploadTransport.swift
//  AppLocalizer
//

import Foundation

/// Where a screenshot push sends its requests: API writes and reads, and
/// the file parts to Apple's upload URLs. The API client is the real one;
/// DEBUG scenes and tests simulate App Store Connect.
protocol ScreenshotUploadTransport: Sendable {
    func send(_ request: PushRequest) async throws -> AppStoreConnectResponse
    func fetch(_ path: String) async throws -> AppStoreConnectResponse
    /// Sends one part of `data`, telling `progress` how many of the part's
    /// bytes went out.
    func upload(_ operation: ScreenshotUploadOperation, data: Data, progress: @escaping @Sendable (Int64) -> Void) async throws
}

extension AppStoreConnectClient: ScreenshotUploadTransport {}
