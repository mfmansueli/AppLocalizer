//
//  DebugSceneTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("DebugScene")
struct DebugSceneTests {
    @Test func readsTheIDAfterTheArgument() {
        #expect(DebugScene.requestedID(in: ["AppLocalizer", "-AppLocalizerDebugScene", "connect"]) == "connect")
    }

    @Test(arguments: [["AppLocalizer"], ["AppLocalizer", "-AppLocalizerDebugScene"]])
    func noIDMeansANormalLaunch(arguments: [String]) {
        #expect(DebugScene.requestedID(in: arguments) == nil)
    }
}
