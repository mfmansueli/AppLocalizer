//
//  AppStoreConnectClient+Send.swift
//  AppLocalizer
//

import Foundation

extension AppStoreConnectClient {
    /// Sends one write a pending change carries (`POST`, `PATCH` or `DELETE`).
    func send(_ request: PushRequest) async throws -> AppStoreConnectResponse {
        try await perform(method: request.method.rawValue, path: request.path, body: request.body)
    }

    /// `GET`s `path` (which may include a query) and returns the raw body,
    /// e.g. for a conflict check.
    func fetch(_ path: String) async throws -> AppStoreConnectResponse {
        try await perform(method: "GET", path: path, body: nil)
    }

    private func perform(method: String, path: String, body: Data?) async throws -> AppStoreConnectResponse {
        guard let url = URL(string: path, relativeTo: Self.baseURL)?.absoluteURL else {
            throw AppStoreConnectError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        try request.setValue("Bearer \(AppStoreConnectJWT.token(for: credentials, issuedAt: now()))", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await transport.send(request)
        guard let http = response as? HTTPURLResponse else { throw AppStoreConnectError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw AppStoreConnectError(statusCode: http.statusCode, body: data)
        }
        let rateLimit = AppStoreConnectRateLimit(header: http.value(forHTTPHeaderField: "X-Rate-Limit"))
        return AppStoreConnectResponse(data: data, rateLimit: rateLimit)
    }
}
