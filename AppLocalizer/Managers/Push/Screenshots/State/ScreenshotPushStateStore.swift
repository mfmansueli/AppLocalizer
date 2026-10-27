//
//  ScreenshotPushStateStore.swift
//  AppLocalizer
//

import Foundation

/// Where each app's `ScreenshotPushState` is kept: a JSON file next to its
/// screenshot document, or memory for tests and DEBUG scenes.
@MainActor
protocol ScreenshotPushStateStore {
    /// The saved state; an empty one when there's none yet.
    func state(appID: String) -> ScreenshotPushState
    func save(_ state: ScreenshotPushState, appID: String) throws
}
