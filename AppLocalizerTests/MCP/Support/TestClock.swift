//
//  TestClock.swift
//  AppLocalizerTests
//

import Foundation

/// A clock tests move by hand, for code expiry and "last seen" times.
final class TestClock: @unchecked Sendable {
    private(set) var now: Date

    init(_ now: Date = Date(timeIntervalSince1970: 1_792_000_000)) {
        self.now = now
    }

    func advance(by interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }
}
