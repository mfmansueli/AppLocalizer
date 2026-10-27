//
//  ScreenshotsEditorUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Store Page → Screenshots' Template and Captions tabs, driven through
/// the DEBUG scenes in `ScreenshotsDebugScenes` (sample documents and a
/// sample translator; nothing leaves the Mac): a template edit saved as a
/// new version, Undo, restoring from History, editing a caption with its
/// live fit, and Translate Missing. The prompt is never copied.
@MainActor
final class ScreenshotsEditorUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Template

    func testATemplateEditIsSavedAsTheNextVersion() {
        app.launch(debugScene: "tpl")
        XCTAssertTrue(element("screenshots.template.canvas").waitForExistence(timeout: 15))
        let version = element("screenshots.template.version")
        XCTAssertTrue(waitForText(version, "v4"), text(of: version))
        XCTAssertFalse(element("screenshots.template.unsaved").exists)

        solidBackground().click()
        XCTAssertTrue(element("screenshots.template.unsaved").waitForExistence(timeout: 5))
        let save = app.buttons["screenshots.template.save"]
        XCTAssertEqual(save.label, "Save as v5")
        save.click()
        XCTAssertTrue(waitForText(version, "v5"), text(of: version))
        XCTAssertTrue(element("screenshots.template.unsaved").waitForNonExistence(timeout: 5))
    }

    func testUndoTakesTheEditBack() {
        app.launch(debugScene: "tpl")
        XCTAssertTrue(element("screenshots.template.canvas").waitForExistence(timeout: 15))
        solidBackground().click()
        let undo = app.buttons["screenshots.template.undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5))
        undo.click()
        XCTAssertTrue(element("screenshots.template.unsaved").waitForNonExistence(timeout: 5))
        XCTAssertTrue(waitForText(element("screenshots.template.version"), "v4"))
    }

    func testRestoringFromHistoryMakesANewVersion() {
        app.launch(debugScene: "tpl-history")
        let restore = app.buttons["screenshots.template.restore.3"]
        XCTAssertTrue(restore.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["screenshots.template.restore.4"].exists)
        restore.click()
        XCTAssertTrue(element("screenshots.template.historyPopover").waitForNonExistence(timeout: 5))
        XCTAssertTrue(waitForText(element("screenshots.template.version"), "v5"))
    }

    func testTheStressStripShowsTheHardestLocales() {
        app.launch(debugScene: "tpl")
        XCTAssertTrue(element("screenshots.template.canvas").waitForExistence(timeout: 15))
        for code in ["en-US", "de-DE", "ar-SA", "ja"] {
            XCTAssertTrue(element("screenshots.template.strip.\(code)").waitForExistence(timeout: 5), code)
        }
        let fit = element("screenshots.template.fit")
        XCTAssertTrue(text(of: fit).contains("1 line too many at 80 u"), text(of: fit))
    }

    // MARK: - Captions

    func testEditingACaptionUpdatesItsFit() {
        app.launch(debugScene: "cap-edit")
        XCTAssertTrue(element("screenshots.captions.editor").waitForExistence(timeout: 15))
        let label = element("screenshots.captions.editor.fitLabel")
        XCTAssertTrue(waitForText(label, "1 line too many at 80 u"), text(of: label))

        let headline = element("screenshots.captions.editor.headline")
        headline.click()
        headline.typeKey("a", modifierFlags: .command)
        headline.typeText("Suche in Sekunden")
        XCTAssertTrue(waitForText(label, "Fits at 112 u"), text(of: label))
        XCTAssertTrue(waitForCellText("screenshots.captions.cell.de-DE.2", containing: "Suche in Sekunden"))
    }

    func testClickingACellOpensTheEditor() {
        app.launch(debugScene: "cap")
        let cell = element("screenshots.captions.cell.fr-FR.0")
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
        cell.click()
        let title = element("screenshots.captions.editor.title")
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: title), "French · slot 1")
        app.buttons["screenshots.captions.editor.close"].click()
        XCTAssertTrue(element("screenshots.captions.editor").waitForNonExistence(timeout: 5))
    }

    func testTranslateMissingOpensWithNothingToTranslate() {
        app.launch(debugScene: "cap")
        let translate = app.buttons["screenshots.captions.translate"]
        XCTAssertTrue(translate.waitForExistence(timeout: 15))
        translate.click()
        XCTAssertTrue(element("screenshots.captions.translateSheet").waitForExistence(timeout: 5))
        let start = app.buttons["screenshots.captions.translate.start"]
        XCTAssertEqual(start.label, "Translate 0")
        XCTAssertFalse(start.isEnabled)
        app.buttons["Cancel"].click()
        XCTAssertTrue(element("screenshots.captions.translateSheet").waitForNonExistence(timeout: 5))
    }

    func testTranslatingWritesTheCheckedLocales() {
        app.launch(debugScene: "cap-translate")
        XCTAssertTrue(element("screenshots.captions.translateSheet").waitForExistence(timeout: 15))
        let summary = element("screenshots.captions.translateSheet.summary")
        XCTAssertTrue(text(of: summary).hasPrefix("20 empty captions in 4 locales."), text(of: summary))
        let start = app.buttons["screenshots.captions.translate.start"]
        XCTAssertTrue(waitForLabel(start, "Translate 20"))

        app.checkBoxes["screenshots.captions.translate.locale.tr"].click()
        XCTAssertTrue(waitForLabel(start, "Translate 15"))
        start.click()
        XCTAssertTrue(element("screenshots.captions.translateSheet").waitForNonExistence(timeout: 5))
        let notice = element("screenshots.notice")
        XCTAssertTrue(notice.waitForExistence(timeout: 20))
        let finished = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "Translated 15 captions", "Translated 15 captions")
        XCTAssertTrue(app.staticTexts.matching(finished).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForCellText("screenshots.captions.cell.pl.2", containing: "Przeszukuj"))
    }

    func testTheBannerShowsTheBatchInProgress() {
        app.launch(debugScene: "cap-translating")
        let progress = element("screenshots.captions.translationProgress")
        XCTAssertTrue(progress.waitForExistence(timeout: 15))
        XCTAssertTrue(waitForText(progress, "Translating with Apple Translation · 7 of 20 · Polish · slot 3"), text(of: progress))
        app.buttons["screenshots.captions.cancelTranslation"].click()
        XCTAssertTrue(element("screenshots.captions.translationBanner").waitForNonExistence(timeout: 5))
    }

    // MARK: - Helpers

    /// The Background picker's Solid segment.
    private func solidBackground() -> XCUIElement {
        let picker = element("screenshots.template.backgroundKind")
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        return picker.radioButtons.element(boundBy: 0)
    }

    /// Waits for a cell's text, which the table fills in once the edit is
    /// written.
    private func waitForCellText(_ identifier: String, containing text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element(identifier))
        return XCTWaiter().wait(for: [expectation], timeout: 10) == .completed
    }

    /// Waits for a static text's value, or an element's label, to read
    /// `expected`.
    private func waitForText(_ element: XCUIElement, _ expected: String) -> Bool {
        let predicate = NSPredicate(format: "value == %@ OR label == %@", expected, expected)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 10) == .completed
    }

    private func waitForLabel(_ element: XCUIElement, _ label: String) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 10) == .completed
    }

    /// A static text's string is its value on macOS; a button's is its label.
    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
