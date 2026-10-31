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

    @Test func thePreviewComesFirst() {
        #expect(ScreenshotsTab.allCases == [.preview, .sets, .template, .captions, .captures])
        #expect(ScreenshotsTab.allCases.map(\.title) == ["Preview", "Sets", "Template", "Captions", "Captures"])
        #expect(ScreenshotsTab.preview.id == "preview")
    }
}
