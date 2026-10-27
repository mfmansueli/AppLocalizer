//
//  AccessibilityChangeTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Accessibility's changes: create or update the family's draft, publish
/// it as the change's option, delete a draft, and the accessibility URL.
@Suite("App Information changes · Accessibility")
struct AccessibilityChangeTests {
    private typealias Support = AppInformationTestSupport
    private let builder = Support.builder
    private let three: Set<AccessibilityFeature> = [.voiceOver, .largerText, .darkInterface]

    @Test func aFamilyWithoutADraftCreatesOneAndPublishesItByItsNewID() throws {
        let card = Support.card(.iPhone, published: [.voiceOver])
        let change = try #require(builder.declarationChange(for: card, answer: AccessibilityAnswer(features: three)))
        #expect(change.id == "appInformation.\(Support.appID).accessibility.IPHONE")
        #expect(change.oldValue == "Published · 1 feature: VoiceOver")
        let create = try #require(change.requests.first)
        #expect(create.method == .post)
        #expect(create.path == "/v1/accessibilityDeclarations")
        let attributes = Support.attributes(create)
        #expect(attributes["deviceFamily"] as? String == "IPHONE")
        #expect(attributes["supportsVoiceover"] as? Bool == true)
        #expect(attributes["supportsLargerText"] as? Bool == true)
        #expect(attributes["supportsVoiceControl"] as? Bool == false)
        let app = ((Support.json(create)["data"] as? [String: Any])?["relationships"] as? [String: Any])?["app"] as? [String: Any]
        #expect((app?["data"] as? [String: Any])?["id"] as? String == Support.appID)
        #expect(change.conflictCheck == nil)

        let option = try #require(change.option)
        #expect(option.isOn)
        #expect(option.isEnabled)
        let publish = try #require(option.requests.first)
        #expect(publish.method == .patch)
        #expect(publish.path == "/v1/accessibilityDeclarations/{createdID}")
        #expect(publish.needsCreatedID)
        #expect(Support.attributes(publish)["publish"] as? Bool == true)
    }

    @Test func aDraftIsUpdatedInPlaceAndCheckedStillADraft() throws {
        let card = Support.card(.iPad, draft: [.voiceOver])
        let change = try #require(builder.declarationChange(for: card, answer: AccessibilityAnswer(features: three)))
        #expect(change.requests.map(\.path) == ["/v1/accessibilityDeclarations/draft-IPAD"])
        #expect(change.requests.first?.method == .patch)
        #expect(Support.attributes(change.requests.first)["deviceFamily"] == nil)
        #expect(change.conflictCheck?.path == "/v1/accessibilityDeclarations/draft-IPAD")
        #expect(change.conflictCheck?.expected == "DRAFT")
        #expect(change.option?.requests.first?.path == "/v1/accessibilityDeclarations/draft-IPAD")
    }

    @Test func anUnchangedDraftOnALiveFamilyOnlyPublishes() throws {
        let card = Support.card(.iPad, draft: three)
        let change = try #require(builder.declarationChange(for: card, answer: AccessibilityAnswer(features: three)))
        #expect(change.requests.isEmpty)
        #expect(change.newValue == "Publish the draft")
        #expect(change.pushRequests.count == 1)
        #expect(builder.declarationChange(for: Support.card(.vision, draft: three, isLive: false), answer: AccessibilityAnswer(features: three)) == nil)
        #expect(builder.declarationChange(for: Support.card(published: three), answer: AccessibilityAnswer(features: three)) == nil)
    }

    @Test func withoutALiveVersionPublishingIsDisabledWithTheReason() throws {
        let card = Support.card(.vision, draft: three, isLive: false)
        let change = try #require(builder.declarationChange(for: card, answer: AccessibilityAnswer(features: [.voiceOver])))
        let option = try #require(change.option)
        #expect(!option.isOn)
        #expect(!option.isEnabled)
        #expect(option.disabledReason == "Apple Vision Pro has no live version yet, so this is saved as a draft. Publish it after 1.4 is released.")
        #expect(change.pushRequests.count == 1)
        #expect(option.footnote?.text(count: 2) == "2 declarations publish immediately when pushed")
    }

    @Test func answeringNoSendsEveryFeatureOff() throws {
        let change = try #require(builder.declarationChange(for: Support.card(published: three), answer: AccessibilityAnswer()))
        let attributes = Support.attributes(change.requests.first)
        for feature in DeviceFamily.iPhone.features {
            #expect(attributes[feature.apiKey] as? Bool == false, "\(feature)")
        }
    }

    @Test func featuresAFamilyDoesntHaveAreNeverSent() throws {
        let change = try #require(builder.declarationChange(for: Support.card(.appleWatch), answer: AccessibilityAnswer(features: [.voiceOver])))
        let attributes = Support.attributes(change.requests.first)
        #expect(attributes["supportsVoiceControl"] == nil)
        #expect(attributes["supportsVoiceover"] as? Bool == true)
    }

    @Test func onlyADraftCanBeDeleted() throws {
        let change = try #require(builder.deleteDraftChange(for: Support.card(.iPad, published: [.voiceOver], draft: three)))
        #expect(change.requests == [PushRequest(method: .delete, path: "/v1/accessibilityDeclarations/draft-IPAD")])
        #expect(change.newValue == "Delete draft")
        #expect(change.conflictCheck?.expected == "DRAFT")
        #expect(builder.deleteDraftChange(for: Support.card(published: three)) == nil)
    }

    @Test func cardsShowWhatsQueued() throws {
        let content = AccessibilityContent(
            families: [.iPhone, .iPad],
            liveFamilies: [.iPhone, .iPad, .appleWatch],
            declarations: [
                AccessibilityDeclaration(id: "p1", family: .iPhone, state: .published, answer: AccessibilityAnswer(features: [.voiceOver])),
                AccessibilityDeclaration(id: "d2", family: .iPad, state: .draft, answer: AccessibilityAnswer(features: three)),
            ],
            accessibilityURL: "",
            upcomingVersion: nil
        )
        let fresh = builder.accessibilityCards(content, with: [])
        let changes = try [
            #require(builder.declarationChange(for: fresh[0], answer: AccessibilityAnswer(features: three))),
            #require(builder.deleteDraftChange(for: fresh[1])),
            #require(builder.declarationChange(for: Support.card(.appleWatch), answer: AccessibilityAnswer(features: [.voiceOver]))),
        ]
        let cards = builder.accessibilityCards(content, with: changes)
        #expect(cards.map(\.family) == [.iPhone, .iPad, .appleWatch])
        #expect(cards[0].queued?.features == three)
        #expect(cards[0].state == .publishedChangesWaiting)
        #expect(cards[1].isDeletionQueued)
        #expect(cards[1].state == .notDeclared)
        #expect(cards[2].state == .draft)
    }

    @Test func theURLIsPatchedOnTheAppAndMustBeHTTPS() throws {
        let change = try #require(builder.accessibilityURLChange(from: "", to: " https://example.com/a11y "))
        #expect(change.requests.first?.path == "/v1/apps/\(Support.appID)")
        #expect(Support.attributes(change.requests.first)["accessibilityUrl"] as? String == "https://example.com/a11y")
        #expect(change.blockedReason == nil)
        #expect(change.oldValue == "Not set")
        #expect(builder.accessibilityURL("", with: [change]) == "https://example.com/a11y")
        #expect(builder.accessibilityURLChange(from: "", to: "example.com/a11y")?.blockedReason != nil)
        #expect(builder.accessibilityURLChange(from: "https://a.com", to: "https://a.com") == nil)
    }
}
