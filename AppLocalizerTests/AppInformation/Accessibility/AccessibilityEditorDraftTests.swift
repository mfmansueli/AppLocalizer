//
//  AccessibilityEditorDraftTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// The editor sheet: Yes/No first, only the family's features, Live / Adds
/// / Removes, Copy from iPhone and assistant suggestions.
@Suite("AccessibilityEditorDraft")
struct AccessibilityEditorDraftTests {
    private typealias Support = AppInformationTestSupport

    @Test func aNeverDeclaredFamilyWaitsForYesOrNo() {
        var draft = AccessibilityEditorDraft(card: Support.card())
        #expect(draft.supportsAny == nil)
        #expect(draft.answer == nil)
        #expect(draft.saveBlocker == "Choose Yes or No first.")

        draft.supportsAny = true
        #expect(draft.saveBlocker == "Check at least one feature, or answer No.")
        draft.toggle(.voiceOver)
        #expect(draft.answer == AccessibilityAnswer(features: [.voiceOver]))

        draft.supportsAny = false
        #expect(draft.answer == AccessibilityAnswer())
        #expect(draft.saveBlocker == nil)
    }

    @Test func itStartsFromWhatTheCardShows() {
        var card = Support.card(published: [.voiceOver])
        card.queued = AccessibilityAnswer(features: [.voiceOver, .captions])
        let draft = AccessibilityEditorDraft(card: card)
        #expect(draft.supportsAny == true)
        #expect(draft.features == [.voiceOver, .captions])
        #expect(draft.published == AccessibilityAnswer(features: [.voiceOver]))
    }

    @Test func rowsSayLiveAddsOrRemovesAgainstWhatsPublished() {
        var draft = AccessibilityEditorDraft(card: Support.card(published: [.voiceOver, .largerText]))
        draft.toggle(.largerText)
        draft.toggle(.captions)
        #expect(draft.status(of: .voiceOver) == .live)
        #expect(draft.status(of: .largerText) == .removes)
        #expect(draft.status(of: .captions) == .adds)
        #expect(draft.status(of: .reducedMotion) == nil)
        #expect(AccessibilityEditorDraft(card: Support.card(draft: [.voiceOver])).status(of: .voiceOver) == nil)
    }

    @Test func watchHidesVoiceControlAndCantCheckIt() {
        var draft = AccessibilityEditorDraft(card: Support.card(.appleWatch))
        #expect(!draft.availableFeatures.contains(.voiceControl))
        draft.supportsAny = true
        draft.toggle(.voiceControl)
        #expect(draft.features.isEmpty)
    }

    @Test func copyFromIPhoneDropsWhatTheFamilyDoesntHave() {
        var draft = AccessibilityEditorDraft(card: Support.card(.appleWatch))
        let dropped = draft.copy(AccessibilityAnswer(features: [.voiceOver, .voiceControl, .largerText]))
        #expect(dropped == [.voiceControl])
        #expect(draft.supportsAny == true)
        #expect(draft.features == [.voiceOver, .largerText])
    }

    @Test func suggestionsForFeaturesTheFamilyLacksAreLeftOut() {
        let suggestions = [
            AccessibilitySuggestion(feature: .darkInterface, supports: true, confidence: .medium, rationale: "Dark variants.", client: "Claude Code"),
            AccessibilitySuggestion(feature: .voiceControl, supports: true, confidence: .low, rationale: "Labels.", client: "Claude Code"),
        ]
        let draft = AccessibilityEditorDraft(card: Support.card(.appleWatch), suggestions: suggestions)
        #expect(draft.suggestion(for: .darkInterface)?.confidence == .medium)
        #expect(draft.suggestion(for: .voiceControl) == nil)
    }
}
