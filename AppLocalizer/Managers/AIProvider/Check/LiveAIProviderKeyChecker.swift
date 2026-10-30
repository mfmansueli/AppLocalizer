//
//  LiveAIProviderKeyChecker.swift
//  AppLocalizer
//

import Foundation

/// The real `AIProviderKeyChecker`: one timed `GET /v1/models/<model>` for
/// the model translations use. A 2xx means the key works and reaches that
/// model; the request costs no tokens.
struct LiveAIProviderKeyChecker: AIProviderKeyChecker {
    var transport: any HTTPTransport = URLSession.shared
    var now: @Sendable () -> Date = { Date() }

    func check(_ apiKey: String, for vendor: AIProviderVendor) async throws -> AIProviderKeyCheck {
        let clock = ContinuousClock()
        let start = clock.now
        let (data, response) = try await transport.send(vendor.api.checkRequest(apiKey: apiKey))
        let elapsed = start.duration(to: clock.now)
        guard let http = response as? HTTPURLResponse else { throw AIProviderError.unreadableResponse(vendor) }
        guard (200..<300).contains(http.statusCode) else {
            throw AIProviderError(vendor: vendor, statusCode: http.statusCode, body: data)
        }
        return AIProviderKeyCheck(vendor: vendor, milliseconds: Int((elapsed / .milliseconds(1)).rounded()), date: now())
    }
}
