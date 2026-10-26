//
//  AppStoreConnectClient.swift
//  AppLocalizer
//

import Foundation

/// Talks to the App Store Connect API with a team API key. Endpoints live
/// in extensions per resource (`AppStoreConnectClient+Apps`, …); this type
/// only builds URLs, signs requests, maps HTTP errors and follows pagination.
struct AppStoreConnectClient: Sendable {
    static let baseURL = URL(string: "https://api.appstoreconnect.apple.com")!

    let credentials: AppStoreConnectCredentials
    var transport: any HTTPTransport = URLSession.shared
    var now: @Sendable () -> Date = { Date() }

    /// Every resource of a collection endpoint, following `links.next` until
    /// the last page.
    func allPages<Attributes>(of path: String, query: [URLQueryItem] = []) async throws -> [AppStoreConnectResource<Attributes>] {
        var next: URL? = url(path, query: query)
        var resources: [AppStoreConnectResource<Attributes>] = []
        while let pageURL = next {
            let page: AppStoreConnectPage<Attributes> = try await get(pageURL)
            resources += page.data
            next = page.links?.next
        }
        return resources
    }

    func get<Response: Decodable>(_ url: URL) async throws -> Response {
        var request = URLRequest(url: url)
        try request.setValue("Bearer \(AppStoreConnectJWT.token(for: credentials, issuedAt: now()))", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await transport.send(request)
        guard let http = response as? HTTPURLResponse else { throw AppStoreConnectError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw AppStoreConnectError(statusCode: http.statusCode, body: data)
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw AppStoreConnectError.unexpectedPayload
        }
    }

    func url(_ path: String, query: [URLQueryItem] = []) -> URL {
        let url = Self.baseURL.appending(path: path)
        return query.isEmpty ? url : url.appending(queryItems: query)
    }
}
