//
//  TranslationPreferences+AIProvider.swift
//  AppLocalizer
//

import Foundation

extension TranslationPreferences {
    /// The selected vendor and its key, for the Translate sheets. Requests
    /// go through `transport` (tests pass a fake).
    func aiProviderSetup(transport: any HTTPTransport = URLSession.shared) -> AIProviderSetup {
        let vendor = vendor
        let key = hasAPIKey ? (try? apiKey()) ?? nil : nil
        return AIProviderSetup(vendor: vendor, hasKey: key != nil) { tone in
            key.map { AIProviderTranslator(vendor: vendor, apiKey: $0, tone: tone, transport: transport) }
        }
    }
}
