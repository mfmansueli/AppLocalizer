//
//  KeyAssistantKeyError.swift
//  AppLocalizer
//

import Foundation

/// Why setup's Check Key failed, in the provider's terms.
enum KeyAssistantKeyError: LocalizedError, Equatable {
    case missing
    /// 401 or 403, or Gemini's 400 for a key it doesn't know.
    case rejected(AIProviderVendor, statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missing:
            String(localized: "Paste a key first.")
        case let .rejected(vendor, statusCode):
            String(localized: "\(vendor.title) rejected this key (\(statusCode)). Check that it was copied in full.")
        }
    }
}
