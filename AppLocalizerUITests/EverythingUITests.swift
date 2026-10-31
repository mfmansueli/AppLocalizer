//
//  EverythingUITests.swift
//  AppLocalizerUITests
//

import AppKit
import XCTest

/// Suggest Everything, opened by board 20's DEBUG scenes: the entry points,
/// the prompt waiting for Claude Code, the progress card and what it does,
/// the run on the Store Page and App Information, the Assistant button's
/// Show Progress, a quiet run, the finished toast with Accept All and Undo,
/// and setup saying why. Suggest Everything… copies its prompt, so the
/// clipboard is saved before each test and put back after.
@MainActor
final class EverythingUITests: XCTestCase {
    private var app: XCUIApplication!
    private var savedClipboard: [[NSPasteboard.PasteboardType: Data]] = []

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        savedClipboard = (NSPasteboard.general.pasteboardItems ?? []).map { item in
            Dictionary(uniqueKeysWithValues: item.types.compactMap { type in item.data(forType: type).map { (type, $0) } })
        }
    }

    override func tearDown() async throws {
        app.terminate()
        NSPasteboard.general.clearContents()
        let items = savedClipboard.map { contents in
            let item = NSPasteboardItem()
            for (type, data) in contents { item.setData(data, forType: type) }
            return item
        }
        NSPasteboard.general.writeObjects(items)
    }

    // MARK: - Starting

    func testOverviewOffersSuggestEverythingInBothCards() {
        app.launch(debugScene: "ev-start")
        let ask = app.buttons["overview.assistantConnected.ask"]
        XCTAssertTrue(ask.waitForExistence(timeout: 10))
        XCTAssertEqual(ask.label, "Suggest Everything…")
        XCTAssertEqual(app.buttons["overview.suggestionsCard.suggest"].label, "Suggest Everything…")
        XCTAssertTrue(element("overview.suggestionsCard.row.ageRating").exists)
    }

    func testThePromptIsCopiedAndWaitsUntilCancelled() {
        app.launch(debugScene: "ev-wait")
        let popover = element("everything.popover")
        XCTAssertTrue(popover.waitForExistence(timeout: 10))
        let prompt = text(of: element("everything.prompt"))
        XCTAssertTrue(prompt.contains("Lumen Journal"))
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), prompt)
        XCTAssertTrue(element("everything.covers.storePage").exists)
        XCTAssertTrue(element("everything.covers.appReview").exists)
        XCTAssertFalse(element("everything.busy").exists)

        app.buttons["everything.cancel"].click()
        XCTAssertTrue(popover.waitForNonExistence(timeout: 5))
        XCTAssertFalse(element("everything.card").exists)
        XCTAssertEqual(app.buttons["overview.assistantConnected.ask"].label, "Suggest Everything…")
    }

    func testThePopoverSaysWhenAPageAskIsStillSending() {
        app.launch(debugScene: "ev-busy")
        let busy = element("everything.busy")
        XCTAssertTrue(busy.waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: busy).contains("still sending Store Page suggestions (2 of 4)"))
    }

    // MARK: - Running

    func testTheProgressCardStopsAndIsDoneWithIt() {
        app.launch(debugScene: "ev-run")
        let header = element("everything.card.header")
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        XCTAssertTrue(header.label.contains("Suggesting everything"))
        XCTAssertTrue(header.label.contains("9 of 18"))
        XCTAssertEqual(text(of: element("overview.suggestionsCard.count")), "Arriving…")
        XCTAssertFalse(app.buttons["overview.suggestionsCard.suggest"].exists)
        XCTAssertTrue(element("everything.row.storePage").exists)

        app.buttons["everything.stop"].click()
        XCTAssertTrue(app.buttons["everything.done"].waitForExistence(timeout: 5))
        XCTAssertTrue(header.label.contains("Stopped receiving"))
        XCTAssertTrue(text(of: element("everything.card.footer")).contains("is refused"))

        app.buttons["everything.done"].click()
        XCTAssertTrue(element("overview.assistantConnected").waitForExistence(timeout: 5))
        XCTAssertFalse(element("everything.card").exists)
    }

    func testTheStorePageShowsTheRunAndWhatsComing() {
        app.launch(debugScene: "ev-run-store")
        let banner = element("suggestions.run")
        XCTAssertTrue(banner.waitForExistence(timeout: 10))
        let bannerText = text(of: element("suggestions.run.text"))
        XCTAssertTrue(bannerText.contains("Suggesting everything · 9 of 18"))
        XCTAssertTrue(bannerText.contains("Here: 0 of 1 arrived."))
        XCTAssertTrue(element("suggestions.coming").exists)
        XCTAssertFalse(app.buttons["suggestions.ask"].exists)

        app.buttons["suggestions.run.overview"].click()
        XCTAssertTrue(element("everything.card").waitForExistence(timeout: 5))
    }

    func testAgeRatingShowsWhatsComing() {
        app.launch(debugScene: "ev-run-info")
        XCTAssertTrue(element("suggestions.run").waitForExistence(timeout: 10))
        XCTAssertTrue(element("suggestions.coming").exists)
    }

    func testTheAssistantButtonShowsProgressInsteadOfAsking() {
        app.launch(debugScene: "ev-run-pop")
        let popover = element("workspace.assistantPopover")
        XCTAssertTrue(popover.waitForExistence(timeout: 10))
        let progress = popover.buttons["assistant.suggestEverything"]
        XCTAssertEqual(progress.label, "Show Progress")
        XCTAssertFalse(popover.buttons["assistant.ask"].exists)

        progress.click()
        XCTAssertTrue(element("everything.card").waitForExistence(timeout: 5))
    }

    func testAQuietRunSaysTheAssistantStoppedSending() {
        app.launch(debugScene: "ev-quiet")
        let header = element("everything.card.header")
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        XCTAssertTrue(header.label.contains("Claude Code stopped sending · 12 of 18"))
        XCTAssertTrue(app.buttons["everything.stop"].exists)
    }

    // MARK: - Finishing

    func testTheLastSuggestionFinishesTheRunAndAcceptAllUndoes() {
        app.launch(debugScene: "ev-done")
        let toast = element("toast.text")
        XCTAssertTrue(toast.waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: toast).hasPrefix("Claude Code sent 18 suggestions"))
        XCTAssertEqual(app.buttons["toast.action"].label, "Review by Area")

        let acceptAll = app.buttons["everything.acceptAll"]
        XCTAssertTrue(acceptAll.waitForExistence(timeout: 5))
        XCTAssertTrue(acceptAll.label.hasPrefix("Accept All ("))
        let count = element("overview.suggestionsCard.count")
        let before = text(of: count)
        acceptAll.click()

        XCTAssertTrue(waitFor(text(of: toast).hasPrefix("Accepted ")))
        XCTAssertTrue(text(of: toast).hasSuffix("Nothing is pushed yet."))
        XCTAssertTrue(element("overview.assistantConnected").waitForExistence(timeout: 5))
        XCTAssertNotEqual(text(of: count), before)

        app.buttons["toast.undo"].click()
        XCTAssertTrue(waitFor(text(of: count) == before))
    }

    func testStoppedRunKeepsWhatArrived() {
        app.launch(debugScene: "ev-stopped")
        let header = element("everything.card.header")
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        XCTAssertTrue(header.label.contains("12 suggestions of 18"))
        XCTAssertTrue(app.buttons["everything.acceptAll"].exists)
    }

    // MARK: - Without an assistant

    func testWithOnlyAKeyItGeneratesTheStorePage() {
        app.launch(debugScene: "ev-key")
        let ask = app.buttons["overview.assistantConnected.ask"]
        XCTAssertTrue(ask.waitForExistence(timeout: 10))
        XCTAssertEqual(ask.label, "Generate Store Page Suggestions…")
        XCTAssertTrue(element("overview.assistantConnected.addOne").exists)
    }

    func testSetupSaysWhyItOpened() {
        app.launch(debugScene: "ev-none")
        let reason = element("assistantSetup.reason")
        XCTAssertTrue(reason.waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: reason).contains("Suggest Everything"))
    }

    // MARK: - Helpers

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    /// Polls until the condition holds, for text that changes in place.
    private func waitFor(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else { return false }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return true
    }
}
