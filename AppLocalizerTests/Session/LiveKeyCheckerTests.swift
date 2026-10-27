//
//  LiveKeyCheckerTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("LiveKeyChecker")
struct LiveKeyCheckerTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private let apps = #"{"data":[{"type":"apps","id":"1"},{"type":"apps","id":"2"}],"meta":{"paging":{"total":6,"limit":200}}}"#

    private func checker(_ responses: [CannedHTTPResponse]) -> (LiveKeyChecker, FakeHTTPTransport) {
        let transport = FakeHTTPTransport(responses)
        return (LiveKeyChecker(transport: transport, now: { [date] in date }), transport)
    }

    @Test func countsAppsAndProbesSalesAndTrends() async throws {
        let (checker, transport) = checker([
            .init(body: apps),
            .init(statusCode: 404, body: #"{"errors":[{"status":"404","code":"NOT_FOUND","detail":"vendor"}]}"#),
        ])
        let check = try await checker.check(TestKeys.credentials())

        #expect(check.appCount == 6)
        #expect(check.salesAccess == .readable)
        #expect(check.date == date)
        #expect(check.milliseconds >= 0)
        let paths = transport.requests.compactMap { $0.url?.path() }
        #expect(paths == ["/v1/apps", "/v1/salesReports"])
        #expect(transport.requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") == true })
    }

    @Test func pageLengthCountsWhenThereIsNoTotal() async throws {
        let (checker, _) = checker([.init(body: #"{"data":[{"type":"apps","id":"1"}]}"#), .init(statusCode: 400, body: "{}")])
        let check = try await checker.check(TestKeys.credentials())
        #expect(check.appCount == 1)
        #expect(check.salesAccess == .readable)
    }

    @Test func forbiddenSalesReportMeansNoSalesAccess() async throws {
        let (checker, _) = checker([.init(body: apps), .init(statusCode: 403, body: "{}")])
        #expect(try await checker.check(TestKeys.credentials()).salesAccess == .notAllowed)
    }

    @Test func serverTroubleLeavesSalesAccessUnknown() async throws {
        let (checker, _) = checker([.init(body: apps), .init(statusCode: 503, body: "{}")])
        #expect(try await checker.check(TestKeys.credentials()).salesAccess == .unknown)
    }

    @Test func rejectedKeyThrowsBeforeTheProbe() async {
        let (checker, transport) = checker([.init(statusCode: 401, body: "{}")])
        await #expect(throws: AppStoreConnectError.unauthorized) {
            _ = try await checker.check(TestKeys.credentials())
        }
        #expect(transport.requests.count == 1)
    }

    @Test func roleThatCantReadAppsThrowsForbidden() async {
        let (checker, _) = checker([.init(statusCode: 403, body: "{}")])
        await #expect(throws: AppStoreConnectError.forbidden(detail: nil)) {
            _ = try await checker.check(TestKeys.credentials())
        }
    }
}
