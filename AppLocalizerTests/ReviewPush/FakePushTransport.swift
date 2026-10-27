//
//  FakePushTransport.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// Records what a push sends. Requests whose path contains a `failures` key
/// throw that error; `responses` are the bodies writes answer with, by path
/// (e.g. a created resource's ID); `remote` answers conflict checks by path.
final class FakePushTransport: PushTransport {
    private let state: Mutex<(sent: [PushRequest], fetched: [String])>
    private let failures: [String: any Error]
    private let remote: [String: Data]
    private let responses: [String: Data]
    private let rateLimit: AppStoreConnectRateLimit?

    init(
        failures: [String: any Error] = [:],
        remote: [String: Data] = [:],
        responses: [String: Data] = [:],
        rateLimit: AppStoreConnectRateLimit? = nil
    ) {
        state = Mutex(([], []))
        self.failures = failures
        self.remote = remote
        self.responses = responses
        self.rateLimit = rateLimit
    }

    var sent: [PushRequest] { state.withLock { $0.sent } }
    var fetched: [String] { state.withLock { $0.fetched } }

    func send(_ request: PushRequest) async throws -> AppStoreConnectResponse {
        state.withLock { $0.sent.append(request) }
        if let failure = failures.first(where: { request.path.contains($0.key) }) { throw failure.value }
        return AppStoreConnectResponse(data: responses[request.path] ?? Data(), rateLimit: rateLimit)
    }

    func fetch(_ path: String) async throws -> AppStoreConnectResponse {
        state.withLock { $0.fetched.append(path) }
        return AppStoreConnectResponse(data: remote[path] ?? Data("{}".utf8), rateLimit: rateLimit)
    }
}
