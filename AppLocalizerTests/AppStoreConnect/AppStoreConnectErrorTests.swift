//
//  AppStoreConnectErrorTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("AppStoreConnectError")
struct AppStoreConnectErrorTests {
    private func body(detail: String?, title: String = "Title") -> Data {
        let detailField = detail.map { #","detail":"\#($0)""# } ?? ""
        return Data(#"{"errors":[{"status":"0","code":"CODE","title":"\#(title)"\#(detailField)}]}"#.utf8)
    }

    @Test(arguments: [
        (401, AppStoreConnectError.unauthorized),
        (403, .forbidden(detail: "Detail")),
        (404, .notFound(detail: "Detail")),
        (429, .rateLimited),
        (500, .server(statusCode: 500, code: "CODE", detail: "Detail")),
    ])
    func statusCodesMapToCases(statusCode: Int, expected: AppStoreConnectError) {
        #expect(AppStoreConnectError(statusCode: statusCode, body: body(detail: "Detail")) == expected)
    }

    @Test(arguments: [409, 422])
    func refusedValuesKeepApplesCode(statusCode: Int) {
        let error = AppStoreConnectError(statusCode: statusCode, body: body(detail: "Not available."))
        #expect(error == .rejected(statusCode: statusCode, code: "CODE", detail: "Not available."))
        #expect(error.pushFailureText == "CODE — Not available.")
    }

    @Test func serverErrorsKeepApplesCode() {
        let error = AppStoreConnectError(statusCode: 500, body: body(detail: "Boom"))
        #expect(error.pushFailureText == "CODE — Boom")
        #expect(AppStoreConnectError.server(statusCode: 503, detail: nil).pushFailureText == "HTTP 503")
    }

    @Test func titleStandsInForAMissingDetail() {
        #expect(AppStoreConnectError(statusCode: 403, body: body(detail: nil, title: "Forbidden")) == .forbidden(detail: "Forbidden"))
    }

    @Test func unreadableBodyHasNoDetail() {
        #expect(AppStoreConnectError(statusCode: 502, body: Data("<html>".utf8)) == .server(statusCode: 502, detail: nil))
    }

    @Test func messageAppendsApplesDetail() throws {
        let message = try #require(AppStoreConnectError.forbidden(detail: "Missing role.").errorDescription)
        #expect(message.hasSuffix(" Missing role."))
    }
}
