//
//  AutopilotStripActionTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// The strip's buttons: their titles and identifiers.
@Suite("AutopilotStripAction")
struct AutopilotStripActionTests {
    private static let all: [AutopilotStripAction] = [.runAutopilot, .open, .setUpAssistant, .importCaptures, .reviewPush]

    @Test(arguments: [
        (AutopilotStripAction.runAutopilot, "Run Autopilot…"),
        (.open, "Open"),
        (.setUpAssistant, "Set Up Assistant…"),
        (.importCaptures, "Import Captures…"),
        (.reviewPush, "Review & Push…"),
    ])
    func eachButtonHasItsTitle(action: AutopilotStripAction, title: String) {
        #expect(action.title == title)
    }

    @Test func openSaysWhatItOpensNextToReviewAndPush() {
        #expect(AutopilotStripAction.open.secondaryTitle == "Open Autopilot")
        for action in Self.all where action != .open {
            #expect(action.secondaryTitle == action.title)
        }
    }

    @Test func identifiersAreDistinctAndNamespaced() {
        let identifiers = Self.all.map(\.identifier)
        #expect(Set(identifiers).count == Self.all.count)
        #expect(identifiers.allSatisfy { $0.hasPrefix("studio.autopilot.") })
        #expect(AutopilotStripAction.runAutopilot.identifier == "studio.autopilot.run")
    }
}
