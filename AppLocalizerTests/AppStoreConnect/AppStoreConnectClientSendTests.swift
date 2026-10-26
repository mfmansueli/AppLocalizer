//
//  AppStoreConnectClientSendTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("AppStoreConnectClient writes")
struct AppStoreConnectClientSendTests {
    private func client(_ transport: FakeHTTPTransport) -> AppStoreConnectClient {
        AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport)
    }

    @Test func sendsTheMethodBodyAndSignature() async throws {
        let transport = FakeHTTPTransport([.init(statusCode: 201, body: "{}", headers: ["X-Rate-Limit": "user-hour-lim:3600;user-hour-rem:3599;"])])
        let body = Data(#"{"data":{"type":"subscriptionPrices"}}"#.utf8)
        let response = try await client(transport).send(PushRequest(method: .post, path: "/v1/subscriptionPrices", body: body))

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.appstoreconnect.apple.com/v1/subscriptionPrices")
        #expect(request.httpBody == body)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") == true)
        #expect(response.rateLimit?.used == 1)
    }

    @Test func fetchKeepsTheQuery() async throws {
        let transport = FakeHTTPTransport([.init(body: #"{"data":[]}"#)])
        let response = try await client(transport).fetch("/v1/subscriptions/1/prices?filter[territory]=BRA&include=subscriptionPricePoint")

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path() == "/v1/subscriptions/1/prices")
        #expect(request.url?.query()?.contains("include=subscriptionPricePoint") == true)
        #expect(request.httpBody == nil)
        #expect(String(data: response.data, encoding: .utf8) == #"{"data":[]}"#)
        #expect(response.rateLimit == nil)
    }

    @Test func refusalsCarryApplesCode() async {
        let body = #"{"errors":[{"status":"409","code":"ENTITY_ERROR.RELATIONSHIP.INVALID","title":"Invalid","detail":"Not available."}]}"#
        let transport = FakeHTTPTransport([.init(statusCode: 409, body: body)])
        await #expect(throws: AppStoreConnectError.rejected(statusCode: 409, code: "ENTITY_ERROR.RELATIONSHIP.INVALID", detail: "Not available.")) {
            try await client(transport).send(PushRequest(method: .patch, path: "/v1/appStoreVersionLocalizations/1"))
        }
    }
}
