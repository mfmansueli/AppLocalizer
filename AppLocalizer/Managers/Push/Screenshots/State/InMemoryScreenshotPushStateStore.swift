//
//  InMemoryScreenshotPushStateStore.swift
//  AppLocalizer
//

import Foundation

/// A push state store that forgets on quit, for tests and DEBUG scenes.
@MainActor
final class InMemoryScreenshotPushStateStore: ScreenshotPushStateStore {
    private(set) var states: [String: ScreenshotPushState]

    init(states: [String: ScreenshotPushState] = [:]) {
        self.states = states
    }

    func state(appID: String) -> ScreenshotPushState {
        states[appID] ?? ScreenshotPushState()
    }

    func save(_ state: ScreenshotPushState, appID: String) throws {
        states[appID] = state
    }
}
