//
//  AppStoreConnectClientTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("AppStoreConnectClient")
struct AppStoreConnectClientTests {
    private func client(_ transport: FakeHTTPTransport) -> AppStoreConnectClient {
        AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport)
    }

    private func appsPage(_ apps: [(id: String, name: String)], next: String? = nil) -> CannedHTTPResponse {
        let data = apps.map { app in
            """
            {"type":"apps","id":"\(app.id)","attributes":{"name":"\(app.name)","bundleId":"com.example.\(app.id)","sku":"SKU\(app.id)","primaryLocale":"en-US"}}
            """
        }
        let links = next.map { #","links":{"self":"https://api.appstoreconnect.apple.com/v1/apps","next":"\#($0)"}"# } ?? ""
        return .init(body: #"{"data":[\#(data.joined(separator: ","))]\#(links)}"#)
    }

    private func queryItems(_ request: URLRequest) -> [String: String] {
        let items = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    // MARK: - Requests

    @Test func appsRequestsTheAppsCollectionSortedByName() async throws {
        let transport = FakeHTTPTransport([appsPage([("1", "Bruma")])])
        _ = try await client(transport).apps()

        let request = try #require(transport.requests.first)
        #expect(request.url?.host() == "api.appstoreconnect.apple.com")
        #expect(request.url?.path() == "/v1/apps")
        #expect(queryItems(request) == ["fields[apps]": "name,bundleId,sku,primaryLocale", "sort": "name", "limit": "200"])
    }

    @Test func requestsCarryASignedBearerToken() async throws {
        let transport = FakeHTTPTransport([appsPage([])])
        _ = try await client(transport).apps()

        let request = try #require(transport.requests.first)
        let authorization = try #require(request.value(forHTTPHeaderField: "Authorization"))
        #expect(authorization.hasPrefix("Bearer "))
        #expect(authorization.dropFirst("Bearer ".count).split(separator: ".").count == 3)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func verifyAccessAsksForASingleApp() async throws {
        let transport = FakeHTTPTransport([appsPage([("1", "Bruma")])])
        try await client(transport).verifyAccess()
        #expect(try queryItems(#require(transport.requests.first))["limit"] == "1")
    }

    // MARK: - Decoding and pagination

    @Test func appsAreDecoded() async throws {
        let transport = FakeHTTPTransport([appsPage([("6443", "Bruma")])])
        let apps = try await client(transport).apps()
        #expect(apps == [StoreApp(id: "6443", name: "Bruma", bundleID: "com.example.6443", sku: "SKU6443", primaryLocale: "en-US")])
    }

    @Test func followsNextLinksUntilTheLastPage() async throws {
        let next = "https://api.appstoreconnect.apple.com/v1/apps?cursor=Mg&limit=200"
        let transport = FakeHTTPTransport([
            appsPage([("1", "Alpha"), ("2", "Beta")], next: next),
            appsPage([("3", "Gamma")]),
        ])
        let apps = try await client(transport).apps()
        #expect(apps.map(\.name) == ["Alpha", "Beta", "Gamma"])
        #expect(transport.requests.count == 2)
        #expect(transport.requests.last?.url?.absoluteString == next)
    }

    // MARK: - Errors

    @Test func unauthorizedMapsTo401() async {
        let body = #"{"errors":[{"status":"401","code":"NOT_AUTHORIZED","title":"Authentication credentials are missing or invalid."}]}"#
        let transport = FakeHTTPTransport([.init(statusCode: 401, body: body)])
        await #expect(throws: AppStoreConnectError.unauthorized) {
            try await client(transport).apps()
        }
    }

    @Test func forbiddenKeepsApplesDetail() async {
        let body = #"{"errors":[{"status":"403","code":"FORBIDDEN_ERROR","title":"Forbidden","detail":"This request is forbidden for security reasons"}]}"#
        let transport = FakeHTTPTransport([.init(statusCode: 403, body: body)])
        await #expect(throws: AppStoreConnectError.forbidden(detail: "This request is forbidden for security reasons")) {
            try await client(transport).apps()
        }
    }

    @Test func nonHTTPResponseIsInvalid() async {
        let transport = FakeHTTPTransport([.init(body: "{}", isHTTP: false)])
        await #expect(throws: AppStoreConnectError.invalidResponse) {
            try await client(transport).apps()
        }
    }

    @Test func malformedBodyIsAnUnexpectedPayload() async {
        let transport = FakeHTTPTransport([.init(body: #"{"data":"nope"}"#)])
        await #expect(throws: AppStoreConnectError.unexpectedPayload) {
            try await client(transport).apps()
        }
    }
}
