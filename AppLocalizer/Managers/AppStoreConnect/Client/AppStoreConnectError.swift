//
//  AppStoreConnectError.swift
//  AppLocalizer
//

import Foundation

/// What can go wrong talking to App Store Connect, with the message the UI
/// shows. HTTP failures carry the first `detail` Apple sent back, if any.
enum AppStoreConnectError: LocalizedError, Equatable {
    /// The `.p8` contents aren't a P-256 private key.
    case invalidPrivateKey
    /// 401: wrong issuer ID / key ID pair, a revoked key, or a bad signature.
    case unauthorized
    /// 403: the key's role can't do this.
    case forbidden(detail: String?)
    case notFound(detail: String?)
    /// 429: the hourly request quota is used up.
    case rateLimited
    /// 409 or 422: Apple refused the value, with its error code, e.g.
    /// `ENTITY_ERROR.RELATIONSHIP.INVALID`.
    case rejected(statusCode: Int, code: String?, detail: String?)
    case server(statusCode: Int, detail: String?)
    /// Not an HTTP response at all.
    case invalidResponse
    /// A 2xx response whose body isn't what the endpoint documents.
    case unexpectedPayload

    init(statusCode: Int, body: Data) {
        let response = try? JSONDecoder().decode(AppStoreConnectErrorResponse.self, from: body)
        let detail = response?.errors.first.flatMap { $0.detail ?? $0.title }
        switch statusCode {
        case 401: self = .unauthorized
        case 403: self = .forbidden(detail: detail)
        case 404: self = .notFound(detail: detail)
        case 409, 422: self = .rejected(statusCode: statusCode, code: response?.errors.first?.code, detail: detail)
        case 429: self = .rateLimited
        default: self = .server(statusCode: statusCode, detail: detail)
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidPrivateKey:
            String(localized: "The private key couldn't be read. Choose the AuthKey .p8 file you downloaded from App Store Connect.")
        case .unauthorized:
            String(localized: "App Store Connect rejected this API key. Check the Issuer ID and Key ID, and that the key hasn't been revoked.")
        case let .forbidden(detail):
            Self.message(String(localized: "This API key isn't allowed to do that. Team keys need the Admin or App Manager role."), detail: detail)
        case let .notFound(detail):
            Self.message(String(localized: "App Store Connect couldn't find that resource."), detail: detail)
        case .rateLimited:
            String(localized: "App Store Connect's hourly request limit was reached. Try again in a few minutes.")
        case let .rejected(statusCode, code, detail):
            Self.message(String(localized: "App Store Connect refused the change (\(code ?? String(statusCode)))."), detail: detail)
        case let .server(statusCode, detail):
            Self.message(String(localized: "App Store Connect returned an error (\(statusCode))."), detail: detail)
        case .invalidResponse:
            String(localized: "App Store Connect sent a response that isn't HTTP.")
        case .unexpectedPayload:
            String(localized: "App Store Connect sent data in an unexpected format.")
        }
    }

    /// Apple's code and detail as the push progress list shows them:
    /// "ENTITY_ERROR.RELATIONSHIP.INVALID — The price point is not available…".
    var pushFailureText: String {
        switch self {
        case let .rejected(statusCode, code, detail):
            [code ?? "HTTP \(statusCode)", detail].compactMap(\.self).joined(separator: " — ")
        case let .server(statusCode, detail):
            ["HTTP \(statusCode)", detail].compactMap(\.self).joined(separator: " — ")
        case let .forbidden(detail):
            ["FORBIDDEN_ERROR", detail].compactMap(\.self).joined(separator: " — ")
        case let .notFound(detail):
            ["NOT_FOUND", detail].compactMap(\.self).joined(separator: " — ")
        default:
            errorDescription ?? ""
        }
    }

    private static func message(_ summary: String, detail: String?) -> String {
        guard let detail, !detail.isEmpty else { return summary }
        return "\(summary) \(detail)"
    }
}
