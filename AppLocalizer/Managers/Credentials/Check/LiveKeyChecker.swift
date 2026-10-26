//
//  LiveKeyChecker.swift
//  AppLocalizer
//

import Foundation

/// The real `KeyChecker`: two signed requests.
///
/// 1. `GET /v1/apps?limit=200`, timed, counts the apps the key sees. A 401
///    or 403 here means the key can't be used.
/// 2. `GET /v1/salesReports` with a placeholder vendor number. The API has
///    no endpoint that names a key's role, but it refuses this request with
///    403 when the role can't read Sales and Trends; any other refusal
///    (such as the unknown vendor number) means the role got past that check.
struct LiveKeyChecker: KeyChecker {
    var transport: any HTTPTransport = URLSession.shared
    var now: @Sendable () -> Date = { Date() }

    static let appsPath = "/v1/apps?fields%5Bapps%5D=name&limit=200"
    static let salesProbePath = "/v1/salesReports?filter%5Bfrequency%5D=DAILY&filter%5BreportType%5D=SALES"
        + "&filter%5BreportSubType%5D=SUMMARY&filter%5BvendorNumber%5D=0"

    func check(_ credentials: AppStoreConnectCredentials) async throws -> KeyAccessCheck {
        let client = AppStoreConnectClient(credentials: credentials, transport: transport, now: now)
        let clock = ContinuousClock()
        let start = clock.now
        let response = try await client.fetch(Self.appsPath)
        let elapsed = start.duration(to: clock.now)
        let page = try? JSONDecoder().decode(AppsPage.self, from: response.data)
        return try await KeyAccessCheck(
            appCount: page?.count ?? 0,
            milliseconds: Int((elapsed / .milliseconds(1)).rounded()),
            salesAccess: salesAccess(client),
            date: now()
        )
    }

    private func salesAccess(_ client: AppStoreConnectClient) async throws -> SalesAccess {
        do {
            _ = try await client.fetch(Self.salesProbePath)
            return .readable
        } catch AppStoreConnectError.forbidden {
            return .notAllowed
        } catch AppStoreConnectError.unauthorized {
            throw AppStoreConnectError.unauthorized
        } catch let error as AppStoreConnectError {
            if case let .server(statusCode, _) = error, statusCode >= 500 { return .unknown }
            if case .rateLimited = error { return .unknown }
            return .readable
        } catch {
            return .unknown
        }
    }

    /// Just enough of the apps page to count it: `meta.paging.total` when
    /// Apple sends it, the page's length otherwise.
    private struct AppsPage: Decodable {
        var data: [AppsPageResource]
        var meta: AppsPageMeta?

        var count: Int { meta?.paging?.total ?? data.count }
    }

    private struct AppsPageResource: Decodable {
        var id: String
    }

    private struct AppsPageMeta: Decodable {
        var paging: AppsPagePaging?
    }

    private struct AppsPagePaging: Decodable {
        var total: Int?
    }
}
