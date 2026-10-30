//
//  LiveKeyAssistantService.swift
//  AppLocalizer
//

import Foundation

/// The real `KeyAssistantService`, through each vendor's `AIProviderAPI`.
/// The key goes only to that vendor.
struct LiveKeyAssistantService: KeyAssistantService {
    var transport: any HTTPTransport = URLSession.shared

    func modelIDs(vendor: AIProviderVendor, apiKey: String) async throws -> [String] {
        let (data, response) = try await transport.send(vendor.api.modelsRequest(apiKey: apiKey))
        guard let http = response as? HTTPURLResponse else { throw AIProviderError.unreadableResponse(vendor) }
        guard (200..<300).contains(http.statusCode) else {
            let error = AIProviderError(vendor: vendor, statusCode: http.statusCode, body: data)
            if case .unauthorized = error { throw KeyAssistantKeyError.rejected(vendor, statusCode: http.statusCode) }
            throw error
        }
        return try vendor.api.modelIDs(from: data)
    }

    func complete(_ completion: AIProviderCompletion, vendor: AIProviderVendor, apiKey: String) async throws -> KeyAssistantAnswer {
        let api = vendor.api
        let clock = ContinuousClock()
        let start = clock.now
        let (data, response) = try await transport.send(api.request(for: completion, apiKey: apiKey))
        let duration = start.duration(to: clock.now)
        guard let http = response as? HTTPURLResponse else { throw AIProviderError.unreadableResponse(vendor) }
        guard (200..<300).contains(http.statusCode) else {
            throw AIProviderError(vendor: vendor, statusCode: http.statusCode, body: data)
        }
        let text = try api.text(from: data).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw AIProviderError.unreadableResponse(vendor) }
        return KeyAssistantAnswer(text: text, tokens: api.tokenCount(from: data), duration: duration)
    }
}
