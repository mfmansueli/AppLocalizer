//
//  FakeLocalHTTPServer.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// A server that never opens a port: `start` reports ready (or `failure`)
/// at once, and the calls are recorded.
final class FakeLocalHTTPServer: LocalHTTPServing, @unchecked Sendable {
    /// When set, `start` fails with this message.
    var failure: String?
    private(set) var startedPorts: [UInt16] = []
    private(set) var stopCount = 0

    func start(port: UInt16, handler _: @escaping Handler, onEvent: @escaping EventHandler) {
        startedPorts.append(port)
        if let failure {
            onEvent(.failed(message: failure))
        } else {
            onEvent(.ready(port: port))
        }
    }

    func stop() {
        stopCount += 1
    }
}
