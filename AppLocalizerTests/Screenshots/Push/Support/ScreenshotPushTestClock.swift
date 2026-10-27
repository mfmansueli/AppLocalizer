//
//  ScreenshotPushTestClock.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization

/// A clock a paused push's waits move forward at once.
final class ScreenshotPushTestClock: Sendable {
    private let date: Mutex<Date>

    init(_ start: Date = ScreenshotPushTestClock.october12) {
        date = Mutex(start)
    }

    /// Oct 12, 2026, 14:32:05.
    static let october12 = DateComponents(
        calendar: Calendar(identifier: .gregorian), year: 2026, month: 10, day: 12, hour: 14, minute: 32, second: 5
    ).date ?? .distantPast

    var now: Date { date.withLock { $0 } }

    func advance(by duration: Duration) {
        date.withLock { $0 = $0.addingTimeInterval(TimeInterval(duration.components.seconds)) }
    }
}
