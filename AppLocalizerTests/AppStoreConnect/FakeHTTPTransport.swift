//
//  FakeHTTPTransport.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// Answers requests with canned responses, in order, and records them.
final class FakeHTTPTransport: HTTPTransport {
    private let state: Mutex<(responses: [CannedHTTPResponse], requests: [URLRequest])>

    init(_ responses: [CannedHTTPResponse]) {
        state = Mutex((responses, []))
    }

    var requests: [URLRequest] { state.withLock { $0.requests } }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let canned = state.withLock { state in
            state.requests.append(request)
            return state.responses.isEmpty ? nil : state.responses.removeFirst()
        }
        guard let canned, let url = request.url else { throw URLError(.badServerResponse) }
        let response: URLResponse = if canned.isHTTP {
            HTTPURLResponse(url: url, statusCode: canned.statusCode, httpVersion: nil, headerFields: canned.headers)!
        } else {
            URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        }
        return (Data(canned.body.utf8), response)
    }
}
