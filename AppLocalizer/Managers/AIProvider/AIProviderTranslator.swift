//
//  AIProviderTranslator.swift
//  AppLocalizer
//

import Foundation

/// `ListingTranslator` backed by the AI provider in Settings → Translation,
/// with the person's own API key. Unlike Apple Translation it knows which
/// field it writes, so keywords are chosen for search and What's New reads
/// naturally, and it keeps the field's limit and the tone. Every language
/// is available; a failure comes back per field with the provider's reason.
struct AIProviderTranslator: ListingTranslator {
    let vendor: AIProviderVendor
    let apiKey: String
    let tone: TranslationTone
    var transport: any HTTPTransport = URLSession.shared

    func availability(from _: StoreLocale, to _: StoreLocale) async -> TranslationAvailability {
        .ready
    }

    func translate(_ text: String, field: ListingField, from source: StoreLocale, to target: StoreLocale) async throws -> String {
        let prompt = AIProviderTranslationPrompt(text: text, field: field, source: source, target: target, tone: tone)
        let api = vendor.api
        let (data, response) = try await transport.send(api.request(for: prompt, apiKey: apiKey))
        guard let http = response as? HTTPURLResponse else { throw AIProviderError.unreadableResponse(vendor) }
        guard (200..<300).contains(http.statusCode) else {
            throw AIProviderError(vendor: vendor, statusCode: http.statusCode, body: data)
        }
        let translated = try api.text(from: data).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !translated.isEmpty else { throw AIProviderError.unreadableResponse(vendor) }
        return translated
    }
}
