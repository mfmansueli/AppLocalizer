//
//  AutopilotPlan+Editing.swift
//  AppLocalizer
//

import Foundation

/// Editing a screen in the Plan table, on whichever device has it.
extension AutopilotPlan {
    /// Changes the screen with `id`: one of the set's, or a device's own.
    mutating func updateScreen(id: String, _ change: (inout AutopilotScreen) -> Void) {
        if let index = screens.firstIndex(where: { $0.id == id }) {
            change(&screens[index])
            return
        }
        guard var sets = deviceScreens else { return }
        for setIndex in sets.indices {
            if let index = sets[setIndex].screens.firstIndex(where: { $0.id == id }) {
                change(&sets[setIndex].screens[index])
                deviceScreens = sets
                return
            }
        }
    }

    /// Removes the screen with `id` from whichever device has it.
    mutating func removeScreen(id: String) {
        screens.removeAll { $0.id == id }
        guard var sets = deviceScreens else { return }
        for index in sets.indices {
            sets[index].screens.removeAll { $0.id == id }
        }
        deviceScreens = sets
    }

    /// Adds a screen at the end of `display`'s: the set's on iPhone and
    /// iPad, its own on Apple Watch and Apple Vision Pro.
    mutating func appendScreen(_ screen: AutopilotScreen, on display: ScreenshotDisplayType) {
        setScreens(screens(on: display) + [screen], on: display)
    }

    /// The caption a screen goes with: its own, or for an Apple Vision Pro
    /// window, its iPhone screen's.
    func caption(of screen: AutopilotScreen) -> String {
        guard screen.caption.isEmpty, let source = screen.sourceScreenID else { return screen.caption }
        return screens.first { $0.id == source }?.caption ?? ""
    }
}
