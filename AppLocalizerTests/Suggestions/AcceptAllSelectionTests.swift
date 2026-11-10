//
//  AcceptAllSelectionTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The Accept All sheet: every suggestion starts ticked; a language, a page
/// or one field can be unticked; and the kinds word the sheet and toasts.
@Suite("Accept All selection")
struct AcceptAllSelectionTests {
    private static func item(_ id: String) -> AcceptAllItem {
        AcceptAllItem(id: id, title: "Keywords", source: .builtIn, current: "", suggested: "diary", reason: "Shorter.")
    }

    private let groups = [
        AcceptAllGroup(id: "en-US", title: "English (U.S.)", regionCode: "US", items: [item("a"), item("b")]),
        AcceptAllGroup(id: "de-DE", title: "German", regionCode: "DE", isNewPage: true, items: [item("c")]),
    ]

    @Test func everythingStartsTickedOnTheFocusedLanguage() {
        let selection = AcceptAllSelection(kind: .storePage, groups: groups, focus: "de-DE")
        #expect(selection.selectedCount == 3)
        #expect(selection.selectedGroupCount == 2)
        #expect(selection.focusedGroup?.id == "de-DE")
        #expect(selection.acceptTitle == "Accept 3 Suggestions")
        #expect(selection.summary == "3 selected in 2 languages")
        #expect(selection.focusedNewPageText == "German isn’t on the App Store yet. Accepting these creates the German page when you push.")
    }

    @Test func anUnknownFocusFallsBackToTheFirstGroup() {
        let selection = AcceptAllSelection(kind: .storePage, groups: groups, focus: "fr-FR")
        #expect(selection.focusedGroupID == "en-US")
        #expect(selection.focusedNewPageText == nil)
    }

    @Test func untickingAGroupThenAnItem() {
        var selection = AcceptAllSelection(kind: .storePage, groups: groups)
        let english = groups[0]
        #expect(selection.state(of: english) == .checked)
        selection.toggle(english.items[0])
        #expect(selection.state(of: english) == .mixed)
        // A mixed group ticks everything again.
        selection.toggle(english)
        #expect(selection.state(of: english) == .checked)
        selection.toggle(english)
        #expect(selection.state(of: english) == .unchecked)
        #expect(selection.selectedCount == 1)
        #expect(selection.acceptTitle == "Accept 1 Suggestion")
        #expect(selection.summary == "1 selected in 1 language")
        selection.selectNone()
        #expect(selection.selectedCount == 0)
        selection.selectAll()
        #expect(selection.selectedCount == 3)
    }

    @Test func theKindsWordTheSheetAndTheToasts() {
        #expect(AcceptAllKind.storePage.countText(32, groups: 6) == "32 Store Page suggestions in 6 languages")
        #expect(AcceptAllKind.screenshots.countText(3, groups: 1) == "3 screenshot caption suggestions in 1 language")
        #expect(AcceptAllKind.appInformation.countText(5, groups: 2) == "5 App Information suggestions on 2 pages")
        #expect(AcceptAllKind.appInformation.groupsTitle == "Pages")
        #expect(AcceptAllKind.storePage.acceptedText(1, groups: 1) == "Accepted 1 suggestion in 1 language. They’re in Review & Push.")
        #expect(AcceptAllKind.storePage.acceptedText(3, groups: 2, withoutAsking: true)
            == "Accepted 3 suggestions in 2 languages, without asking. They’re in Review & Push.")
        #expect(AcceptAllKind.appInformation.acceptedText(2, groups: 1, turnedOffAsking: true)
            == "Accepted 2 suggestions in 1 page. They’re in Review & Push. Next time, Accept All won’t ask first.")
    }
}
