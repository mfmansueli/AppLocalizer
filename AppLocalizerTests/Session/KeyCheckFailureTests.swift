//
//  KeyCheckFailureTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("KeyCheckFailure")
struct KeyCheckFailureTests {
    @Test func appleAnswersMapToTheDesignsErrors() {
        #expect(KeyCheckFailure(AppStoreConnectError.unauthorized) == .rejected)
        #expect(KeyCheckFailure(AppStoreConnectError.forbidden(detail: "role")) == .roleTooLow)
        #expect(KeyCheckFailure(AppStoreConnectError.rateLimited) == .other(AppStoreConnectError.rateLimited.errorDescription ?? ""))
    }

    @Test(arguments: [URLError.Code.notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .timedOut])
    func networkErrorsMeanOffline(code: URLError.Code) {
        #expect(KeyCheckFailure(URLError(code)) == .offline)
    }

    @Test func otherURLErrorsKeepTheirMessage() {
        let error = URLError(.badServerResponse)
        #expect(KeyCheckFailure(error) == .other(error.localizedDescription))
    }

    @Test func titlesNameTheStatusCode() {
        #expect(KeyCheckFailure.rejected.title.contains("401"))
        #expect(KeyCheckFailure.roleTooLow.title.contains("403"))
        #expect(KeyCheckFailure.roleTooLow.message.contains("App Manager"))
        #expect(KeyCheckFailure.other("Nope").message == "Nope")
    }
}
