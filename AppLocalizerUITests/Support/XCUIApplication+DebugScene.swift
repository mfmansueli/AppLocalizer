//
//  XCUIApplication+DebugScene.swift
//  AppLocalizerUITests
//

import XCTest

extension XCUIApplication {
    /// Launches AppLocalizer on a DEBUG scene. Saved window state is
    /// ignored: when an earlier run left the main window closed, macOS would
    /// otherwise restore no window at all.
    func launch(debugScene scene: String) {
        launchArguments = ["-AppLocalizerDebugScene", scene, "-ApplePersistenceIgnoreState", "YES"]
        launch()
    }
}
