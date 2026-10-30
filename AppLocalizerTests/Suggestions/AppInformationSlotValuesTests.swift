//
//  AppInformationSlotValuesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Reading and writing slots on Lumen's sample: Age Rating with Wellness
/// unanswered, Accessibility with iPhone published and Apple Watch not
/// declared, and Apple Watch from Other Devices for an iPhone-only app.
@Suite("App Information slot values")
struct AppInformationSlotValuesTests {
    private let content = DebugAppInformationContent.lumen(versionID: nil)
    private let accessibility = DebugAppInformationContent.accessibility(.lumen)
    private let claude = ChangeSource.assistant(client: "Claude Code")

    private func values(_ changes: [PendingChange] = [], accessibility: AccessibilityContent? = nil) -> AppInformationSlotValues {
        let builder = AppInformationChangeBuilder(appID: DebugFixtures.AppID.lumen, ids: content.ids, versionString: content.version?.versionString)
        return AppInformationSlotValues(content: content, accessibility: accessibility ?? self.accessibility, builder: builder, changes: changes)
    }

    @Test func unansweredReadsEmptyAndAnsweredByRawValue() {
        let values = values()
        #expect(values.value(.ageRating(.wellness)) == "")
        #expect(values.value(.ageRating(.horror)) == "none")
        #expect(values.value(.accessibility(.iPhone, .voiceOver)) == "yes")
        #expect(values.value(.accessibility(.iPhone, .reducedMotion)) == "no")
        #expect(values.value(.accessibility(.appleWatch, .voiceOver)) == "")
    }

    @Test func anAnswerQueuesTheQuestionsChange() throws {
        let written = try #require(values().change(.ageRating(.wellness), to: "affirmative", source: claude))
        let change = try #require(written.change)
        #expect(change.source == claude)
        let after = values([change])
        #expect(after.value(.ageRating(.wellness)) == "affirmative")
        #expect(after.isPending(.ageRating(.wellness)))
        #expect(after.liveValue(.ageRating(.wellness)) == "")
        #expect(values().change(.ageRating(.wellness), to: "", source: .you)?.change == nil)
        #expect(values().change(.ageRating(.wellness), to: "maybe", source: .you) == nil)
    }

    @Test func aFeatureQueuesTheDevicesDeclarationAndTheNextBuildsOnIt() throws {
        let first = try #require(values().change(.accessibility(.appleWatch, .voiceOver), to: "yes", source: claude)?.change)
        let second = try #require(values([first]).change(.accessibility(.appleWatch, .largerText), to: "yes", source: claude)?.change)
        #expect(first.id == second.id)
        let after = values([second])
        #expect(after.value(.accessibility(.appleWatch, .voiceOver)) == "yes")
        #expect(after.value(.accessibility(.appleWatch, .largerText)) == "yes")
        #expect(after.value(.accessibility(.appleWatch, .reducedMotion)) == "no")
        #expect(after.isPending(.accessibility(.appleWatch, .largerText)))
        #expect(!after.isPending(.accessibility(.iPhone, .voiceOver)))
        #expect(values().change(.accessibility(.appleWatch, .voiceOver), to: "maybe", source: .you) == nil)
    }

    @Test func iPhonesPublishedAnswerIsntPendingUntilItChanges() throws {
        let values = values()
        #expect(!values.isPending(.accessibility(.iPhone, .reducedMotion)))
        let change = try #require(values.change(.accessibility(.iPhone, .reducedMotion), to: "yes", source: .you)?.change)
        #expect(self.values([change]).isPending(.accessibility(.iPhone, .reducedMotion)))
        #expect(!self.values([change]).isPending(.accessibility(.iPhone, .voiceOver)))
    }

    @Test func anIPhoneAppCanDeclareAppleWatchFromOtherDevices() {
        var iPhoneOnly = accessibility
        iPhoneOnly.families = [.iPhone]
        let values = values(accessibility: iPhoneOnly)
        #expect(values.otherFamilies == [.appleWatch])
        #expect(values.accessibilityFamilies == [.iPhone, .appleWatch])
        #expect(values.card(for: .appleWatch)?.shown == nil)
        #expect(values.canSuggest(.accessibility(.appleWatch, .voiceOver)))
        #expect(values.card(for: .mac) == nil)
        #expect(!values.canSuggest(.accessibility(.mac, .voiceOver)))
    }

    @Test func beforeAccessibilityLoadsNoFeatureCanTakeAValue() {
        let builder = AppInformationChangeBuilder(appID: DebugFixtures.AppID.lumen, ids: content.ids, versionString: nil)
        let values = AppInformationSlotValues(content: content, accessibility: nil, builder: builder, changes: [])
        #expect(values.accessibilityFamilies.isEmpty)
        #expect(!values.canSuggest(.accessibility(.iPhone, .voiceOver)))
        #expect(values.value(.accessibility(.iPhone, .voiceOver)) == "")
        #expect(values.canSuggest(.ageRating(.wellness)))
    }
}
#endif
