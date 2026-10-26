//
//  DebugHoldingPushTransport.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Simulates App Store Connect for `a11y-pushing`: every request succeeds
/// quickly, a `POST` answers with a made-up ID, and the publish request
/// for the declaration whose path contains `holding` never finishes, so
/// the progress stays at "Publishing…".
final class DebugHoldingPushTransport: PushTransport {
    private let holding: String

    init(holding: String) {
        self.holding = holding
    }

    func send(_ request: PushRequest) async throws -> AppStoreConnectResponse {
        let body = request.body.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        if request.path.contains(holding), body.contains(#""publish":true"#) {
            try await Task.sleep(for: .seconds(24 * 60 * 60))
        }
        try await Task.sleep(for: .milliseconds(150))
        let created = #"{"data":{"type":"accessibilityDeclarations","id":"debug-\#(UUID().uuidString)"}}"#
        return AppStoreConnectResponse(data: Data((request.method == .post ? created : "{}").utf8), rateLimit: nil)
    }

    func fetch(_: String) async throws -> AppStoreConnectResponse {
        AppStoreConnectResponse(data: Data("{}".utf8), rateLimit: nil)
    }
}
#endif
