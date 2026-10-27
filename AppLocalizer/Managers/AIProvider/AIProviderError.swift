//
//  AIProviderError.swift
//  AppLocalizer
//

import Foundation

/// Why the AI provider didn't translate a field, as the batch shows it.
/// HTTP failures carry the provider's own message when it sent one.
enum AIProviderError: LocalizedError, Equatable {
    /// 401 or 403: a wrong or revoked key, or one without access.
    case unauthorized(AIProviderVendor)
    /// 429: the account's rate limit or spending limit.
    case rateLimited(AIProviderVendor)
    /// 500, 503 or 529: the provider is down or overloaded.
    case unavailable(AIProviderVendor)
    /// The model declined to translate the text.
    case declined(AIProviderVendor)
    /// The answer hit the output limit before it ended.
    case cutOff(AIProviderVendor)
    case rejected(AIProviderVendor, statusCode: Int, message: String?)
    case unreadableResponse(AIProviderVendor)

    init(vendor: AIProviderVendor, statusCode: Int, body: Data) {
        switch statusCode {
        case 401, 403: self = .unauthorized(vendor)
        case 429: self = .rateLimited(vendor)
        case 500, 502, 503, 504, 529: self = .unavailable(vendor)
        default:
            // Anthropic and OpenAI both send `{"error": {"message": …}}`.
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: body))?.error?.message
            self = .rejected(vendor, statusCode: statusCode, message: message)
        }
    }

    var errorDescription: String? {
        switch self {
        case let .unauthorized(vendor):
            String(localized: "\(vendor.title) rejected the API key. Check it in Settings → Translation.")
        case let .rateLimited(vendor):
            String(localized: "\(vendor.title)’s rate limit was reached. Try again in a minute.")
        case let .unavailable(vendor):
            String(localized: "\(vendor.title) is unavailable right now. Try again shortly.")
        case let .declined(vendor):
            String(localized: "\(vendor.title) declined to translate this text.")
        case let .cutOff(vendor):
            String(localized: "\(vendor.title)’s answer was cut off.")
        case let .rejected(vendor, statusCode, message):
            [String(localized: "\(vendor.title) returned an error (\(statusCode))."), message].compactMap(\.self).joined(separator: " ")
        case let .unreadableResponse(vendor):
            String(localized: "\(vendor.title) sent an answer this app can’t read.")
        }
    }

    private struct ErrorBody: Decodable {
        let error: Detail?
    }

    private struct Detail: Decodable {
        let message: String?
    }
}
