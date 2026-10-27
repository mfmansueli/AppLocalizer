//
//  AppInformationErrorReporter.swift
//  AppLocalizer
//

import Foundation

/// Turns a failed App Information load into what the page shows, and tells
/// the workspace banner about the connection, the rate limit or Apple's
/// error.
enum AppInformationErrorReporter {
    @MainActor
    static func report(_ error: any Error, to push: PushController?, now: Date = .now) -> String {
        if let error = error as? AppStoreConnectError {
            switch error {
            case .rateLimited:
                let start = Calendar.current.dateInterval(of: .hour, for: now)?.start ?? now
                push?.report(.rateLimited(resumeAt: start.addingTimeInterval(3600)))
            case .notFound: break
            default: push?.report(.apiError(error.pushFailureText))
            }
            return error.errorDescription ?? error.localizedDescription
        }
        if let error = error as? URLError, offlineCodes.contains(error.code) {
            push?.report(.offline)
        }
        return error.localizedDescription
    }

    /// The line under "Couldn't load accessibility declarations.": the
    /// status, Apple's code or detail, and the request, e.g. "500 ·
    /// UNEXPECTED_ERROR · GET /v1/apps/…/accessibilityDeclarations".
    static func requestLine(for error: any Error, request: String) -> String {
        var parts: [String] = []
        if let error = error as? AppStoreConnectError {
            switch error {
            case let .rejected(statusCode, code, detail): parts += [String(statusCode), code ?? detail].compactMap(\.self)
            case let .server(statusCode, code, detail): parts += [String(statusCode), code ?? detail].compactMap(\.self)
            case let .forbidden(detail): parts += ["403", detail].compactMap(\.self)
            case let .notFound(detail): parts += ["404", detail].compactMap(\.self)
            case .unauthorized: parts.append("401")
            case .rateLimited: parts.append("429")
            case .invalidPrivateKey, .invalidResponse, .unexpectedPayload: parts.append(error.errorDescription ?? "")
            }
        } else {
            parts.append(error.localizedDescription)
        }
        return (parts + ["GET \(request)"]).joined(separator: " · ")
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .timedOut, .dnsLookupFailed,
    ]
}
