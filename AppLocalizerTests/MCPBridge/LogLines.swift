//
//  LogLines.swift
//  AppLocalizerTests
//

import Foundation

/// Collects what the bridge logs, from any thread.
final class LogLines: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []

    func append(_ line: String) {
        lock.withLock { lines.append(line) }
    }

    var all: [String] {
        lock.withLock { lines }
    }
}
