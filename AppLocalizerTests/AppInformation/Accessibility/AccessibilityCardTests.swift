//
//  AccessibilityCardTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// A family card's state badge, blue pills, Live now → after publishing,
/// note and Delete Draft.
@Suite("AccessibilityCard")
struct AccessibilityCardTests {
    private typealias Support = AppInformationTestSupport
    private let six: Set<AccessibilityFeature> = [.voiceOver, .voiceControl, .largerText, .sufficientContrast, .darkInterface, .differentiateWithoutColor]

    @Test func statesFollowWhatsPublishedDraftedAndQueued() {
        #expect(Support.card().state == .notDeclared)
        #expect(Support.card(draft: six).state == .draft)
        #expect(Support.card(.vision, draft: six, isLive: false).state == .draftCantPublish)
        #expect(Support.card(published: six).state == .published)
        #expect(Support.card(published: six, draft: [.voiceOver]).state == .publishedChangesWaiting)
        var queued = Support.card(published: six)
        queued.queued = AccessibilityAnswer(features: six.union([.reducedMotion]))
        #expect(queued.state == .publishedChangesWaiting)
        #expect(queued.hasPendingChange)
    }

    @Test func unpublishedFeaturesAreTheBluePills() {
        var card = Support.card(published: six)
        #expect(card.unpublishedFeatures.isEmpty)
        card.queued = AccessibilityAnswer(features: six.union([.reducedMotion]))
        #expect(card.unpublishedFeatures == [.reducedMotion])
        #expect(Support.card(.iPad, draft: [.voiceOver]).unpublishedFeatures == [.voiceOver])
    }

    @Test func liveNowAfterPublishingListsAddedAndRemoved() throws {
        var card = Support.card(published: six)
        card.queued = AccessibilityAnswer(features: six.subtracting([.voiceControl]).union([.reducedMotion]))
        let changes = try #require(card.changesAfterPublishing)
        #expect(changes.added == [.reducedMotion])
        #expect(changes.removed == [.voiceControl])
        #expect(Support.card(published: six).changesAfterPublishing == nil)
    }

    @Test func theNoteExplainsTheState() {
        #expect(Support.card(draft: six).note == "Saved in App Store Connect as a draft. It isn’t on the product page.")
        let vision = Support.card(.vision, draft: six, isLive: false).note
        #expect(vision == """
        No live version on Apple Vision Pro yet. Apple only publishes labels for live devices, so this stays a draft until 1.4 is released.
        """)
        var queued = Support.card(published: six)
        queued.queued = AccessibilityAnswer(features: [.voiceOver])
        #expect(queued.note == "Live on the product page as shown; the changes publish when you push them.")
        #expect(Support.card(published: six).note == nil)
    }

    @Test func onlyADraftCanBeDeletedAndAQueuedDeletionShowsWhatStays() {
        #expect(Support.card(draft: six).canDeleteDraft)
        #expect(!Support.card(published: six).canDeleteDraft)
        var card = Support.card(published: [.voiceOver], draft: six)
        card.isDeletionQueued = true
        #expect(!card.canDeleteDraft)
        #expect(card.shown?.features == [.voiceOver])
        #expect(card.state == .published)
    }

    @Test func theSummarySaysHowManyAndWhich() {
        #expect(AccessibilityAnswer(features: [.largerText, .voiceOver]).summary == "2 features: VoiceOver, Larger Text")
        #expect(AccessibilityAnswer(features: [.captions]).summary == "1 feature: Captions")
        #expect(AccessibilityAnswer().summary == "Doesn’t indicate support")
        #expect(AccessibilityAnswer(supports: ["supportsVoiceover": true, "supportsCaptions": false]).features == [.voiceOver])
    }
}
