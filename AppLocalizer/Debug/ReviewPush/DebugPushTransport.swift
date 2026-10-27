//
//  DebugPushTransport.swift
//  AppLocalizer
//

#if DEBUG
import Foundation
import Synchronization

/// Simulates App Store Connect for DEBUG scenes: every request takes
/// `delay`, requests whose path or body contains a `failures` key are
/// refused with that error, `remoteValues` answer conflict checks, a `POST`
/// answers with a made-up ID for the resource it "created", and the hourly
/// quota counts up from `usedThisHour`.
final class DebugPushTransport: PushTransport {
    private let delay: Duration
    private let failures: [String: AppStoreConnectError]
    private let remoteValues: [String: String]
    private let used: Mutex<Int>

    init(
        delay: Duration = .milliseconds(150),
        failures: [String: AppStoreConnectError] = [:],
        remoteValues: [String: String] = [:],
        usedThisHour: Int = 441
    ) {
        self.delay = delay
        self.failures = failures
        self.remoteValues = remoteValues
        used = Mutex(usedThisHour)
    }

    func send(_ request: PushRequest) async throws -> AppStoreConnectResponse {
        try await Task.sleep(for: delay)
        let rateLimit = countRequest()
        let body = request.body.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        if let failure = failures.first(where: { request.path.contains($0.key) || body.contains($0.key) }) {
            throw failure.value
        }
        let created = #"{"data":{"type":"debug","id":"debug-\#(UUID().uuidString)"}}"#
        return AppStoreConnectResponse(data: Data((request.method == .post ? created : "{}").utf8), rateLimit: rateLimit)
    }

    /// Answers with `{"value": …}`; conflict checks in DEBUG data read
    /// `["value"]`.
    func fetch(_ path: String) async throws -> AppStoreConnectResponse {
        try await Task.sleep(for: delay)
        let rateLimit = countRequest()
        let object: [String: String] = remoteValues[path].map { ["value": $0] } ?? [:]
        let data = try JSONSerialization.data(withJSONObject: object)
        return AppStoreConnectResponse(data: data, rateLimit: rateLimit)
    }

    private func countRequest() -> AppStoreConnectRateLimit {
        let count = used.withLock { value in
            value += 1
            return value
        }
        let limit = AppStoreConnectRateLimit.defaultHourlyLimit
        return AppStoreConnectRateLimit(limit: limit, remaining: max(0, limit - count))
    }
}
#endif
