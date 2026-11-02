//
//  HTTPTransport.swift
//  AppLocalizer
//

import Foundation

/// Sends one request. `URLSession` is the real one; tests answer with
/// canned responses so no unit test ever reaches Apple.
protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
    /// Sends `body`, telling `progress` how many of its bytes went out.
    func upload(_ request: URLRequest, body: Data, progress: @escaping @Sendable (Int64) -> Void) async throws -> (Data, URLResponse)
}

extension HTTPTransport {
    /// Without a way to watch it: the whole body once it's sent.
    func upload(_ request: URLRequest, body: Data, progress: @escaping @Sendable (Int64) -> Void) async throws -> (Data, URLResponse) {
        var request = request
        request.httpBody = body
        let response = try await send(request)
        progress(Int64(body.count))
        return response
    }
}
