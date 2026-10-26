//
//  HTTPTransport.swift
//  AppLocalizer
//

import Foundation

/// Sends one request. `URLSession` is the real one; tests answer with
/// canned responses so no unit test ever reaches Apple.
protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}
