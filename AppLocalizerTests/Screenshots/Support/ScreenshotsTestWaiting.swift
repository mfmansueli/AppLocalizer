//
//  ScreenshotsTestWaiting.swift
//  AppLocalizerTests
//

import Foundation

/// Waits for work a view model starts in its own task, polling every few
/// milliseconds for up to two seconds.
enum ScreenshotsTestWaiting {
    /// Returns whether `condition` became true in time.
    @MainActor
    @discardableResult
    static func until(_ condition: @MainActor () -> Bool) async -> Bool {
        for _ in 0..<400 {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return condition()
    }
}
