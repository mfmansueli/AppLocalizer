//
//  ChangeOptionTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The generic option a review row can show under a change ("Publish to the
/// App Store"): what it sends, what it says, and the queue keeping the choice.
@MainActor
@Suite("ChangeOption")
struct ChangeOptionTests {
    static let publish = PushRequest(method: .patch, path: "/v1/accessibilityDeclarations/d1", body: Data(#"{"publish":true}"#.utf8))

    static func option(isOn: Bool = true, disabledReason: String? = nil) -> ChangeOption {
        ChangeOption(
            title: "Publish to the App Store",
            isOn: isOn,
            onNote: "Goes live.",
            offNote: "Saved as a draft.",
            disabledReason: disabledReason,
            requests: [publish],
            progressTitle: "Publishing…",
            doneTitle: "Published",
            offDoneTitle: "Saved as a draft",
            footnote: ChangeOptionFootnote(one: "1 declaration publishes", other: "{count} declarations publish")
        )
    }

    static func change(id: String = "a11y.iphone", option: ChangeOption?) -> PendingChange {
        var change = PendingChange(
            id: id,
            appID: "lumen",
            section: .appInformation,
            group: "App Information · Accessibility",
            title: "iPhone",
            oldValue: "Not declared",
            newValue: "2 features",
            requests: [PushRequest(method: .patch, path: "/v1/accessibilityDeclarations/d1")]
        )
        change.option = option
        return change
    }

    @Test func anOptionThatIsOnAddsItsRequestsAfterTheChangesOwn() {
        let change = Self.change(option: Self.option())
        #expect(change.pushRequests.map(\.path) == ["/v1/accessibilityDeclarations/d1", "/v1/accessibilityDeclarations/d1"])
        #expect(change.pushRequests.last == Self.publish)
        #expect(change.estimatedRequestCount == 2)
    }

    @Test func anOptionThatIsOffOrDisabledSendsOnlyTheChangesOwnRequests() {
        #expect(Self.change(option: Self.option(isOn: false)).pushRequests.count == 1)
        let disabled = Self.option(isOn: true, disabledReason: "No live version.")
        #expect(!disabled.isEffective)
        #expect(Self.change(option: disabled).pushRequests.count == 1)
        #expect(Self.change(option: nil).pushRequests.count == 1)
    }

    @Test func theNoteAndTheFinishedTitleFollowTheSwitch() {
        #expect(Self.option().note == "Goes live.")
        #expect(Self.option().finishedTitle == "Published")
        #expect(Self.option(isOn: false).note == "Saved as a draft.")
        #expect(Self.option(isOn: false).finishedTitle == "Saved as a draft")
        let disabled = Self.option(disabledReason: "No live version.")
        #expect(disabled.note == "No live version.")
        #expect(disabled.finishedTitle == "Saved as a draft")
    }

    @Test func theFootnoteSaysOneOrCounts() {
        let footnote = ChangeOptionFootnote(one: "1 declaration publishes", other: "{count} declarations publish")
        #expect(footnote.text(count: 1) == "1 declaration publishes")
        #expect(footnote.text(count: 3) == "3 declarations publish")
    }

    @Test func theQueueKeepsTheSwitchButNeverTurnsOnADisabledOne() {
        let queue = ChangeQueue(changes: [
            Self.change(id: "on", option: Self.option()),
            Self.change(id: "disabled", option: Self.option(isOn: false, disabledReason: "No live version.")),
            Self.change(id: "none", option: nil),
        ])

        queue.setOption(id: "on", isOn: false)
        queue.setOption(id: "disabled", isOn: true)
        queue.setOption(id: "none", isOn: true)

        #expect(queue.change(id: "on")?.option?.isOn == false)
        #expect(queue.change(id: "disabled")?.option?.isOn == false)
        #expect(queue.change(id: "none")?.option == nil)
    }

    @Test func roundTripsAndOlderSavedChangesWithoutAnOptionStillDecode() throws {
        let change = Self.change(option: Self.option())
        let decoded = try JSONDecoder().decode(PendingChange.self, from: JSONEncoder().encode(change))
        #expect(decoded == change)

        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(Self.change(option: nil))) as? [String: Any])
        object.removeValue(forKey: "option")
        let older = try JSONDecoder().decode(PendingChange.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(older.option == nil)
    }
}
