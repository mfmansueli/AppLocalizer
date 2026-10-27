//
//  ScreenshotsTabTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("ScreenshotsTab")
struct ScreenshotsTabTests {
    @Test func onlyTheTemplateEditorHidesTheSidebar() {
        #expect(ScreenshotsTab.allCases.filter(\.hidesSidebar) == [.template])
    }
}
