//
//  CannedHTTPResponse.swift
//  AppLocalizerTests
//

import Foundation

/// One answer `FakeHTTPTransport` gives.
struct CannedHTTPResponse: Sendable {
    var statusCode = 200
    var body: String
    /// A plain `URLResponse` instead of an `HTTPURLResponse`.
    var isHTTP = true
    var headers: [String: String] = [:]
}
