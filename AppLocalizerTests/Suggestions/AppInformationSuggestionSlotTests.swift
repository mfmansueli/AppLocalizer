//
//  AppInformationSuggestionSlotTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What an App Information suggestion is for: the slot a target names, the
/// answers a question or feature takes, and an assistant's value read as
/// one of them.
@Suite("App Information suggestion slots")
struct AppInformationSuggestionSlotTests {
    @Test func targetsRoundTrip() {
        let slots: [AppInformationSuggestionSlot] = [.field(.notes), .ageRating(.wellness), .accessibility(.appleWatch, .voiceOver)]
        for slot in slots {
            #expect(AppInformationSuggestionSlot(target: slot.target) == slot)
        }
        #expect(AppInformationSuggestionSlot.accessibility(.iPhone, .largerText).scope == .accessibility(.iPhone))
        #expect(AppInformationSuggestionSlot.ageRating(.wellness).scope == .appInformation(.ageRating))
    }

    @Test func aTargetThatIsntOneIsNil() {
        #expect(AppInformationSuggestionSlot(target: SuggestionTarget(.accessibility(.appleWatch), field: "voiceControl")) == nil)
        #expect(AppInformationSuggestionSlot(target: SuggestionTarget(.appInformation(.ageRating), field: "copyright")) == nil)
        #expect(AppInformationSuggestionSlot(target: SuggestionTarget(.appInformation(.general), field: "notes")) == nil)
        #expect(AppInformationSuggestionSlot(target: .storePage(.englishUS, .subtitle)) == nil)
    }

    @Test func choicesHaveNoUseAndEdit() {
        #expect(AppInformationSuggestionSlot.field(.notes).canUseAndEdit)
        #expect(!AppInformationSuggestionSlot.field(.primaryCategory).canUseAndEdit)
        #expect(!AppInformationSuggestionSlot.ageRating(.wellness).canUseAndEdit)
        #expect(AppInformationSuggestionSlot.accessibility(.iPhone, .voiceOver).isChoice)
        #expect(!AppInformationSuggestionSlot.field(.copyright).isChoice)
    }

    @Test func answersReadByName() {
        let wellness = AppInformationSuggestionSlot.ageRating(.wellness)
        #expect(wellness.displayValue("affirmative") == "Yes")
        #expect(wellness.displayValue("") == "Not answered")
        #expect(wellness.choiceList == "No, Yes")
        #expect(AppInformationSuggestionSlot.ageRating(.horror).choiceList == "None, Infrequent, Frequent")
        let voiceOver = AppInformationSuggestionSlot.accessibility(.iPhone, .voiceOver)
        #expect(voiceOver.displayValue("yes") == "Yes")
        #expect(voiceOver.displayValue("") == "Not answered")
    }

    @Test(arguments: [
        ("Yes", "affirmative"), ("affirmative", "affirmative"), (" no ", "negative"), ("TRUE", "affirmative"), ("false", "negative"),
    ])
    func aYesNoQuestionTakesANameAnIDOrABoolean(sent: String, stored: String) {
        #expect(AppInformationSuggestionSlot.ageRating(.wellness).normalized(sent) == stored)
    }

    @Test func aLevelQuestionTakesOnlyItsLevels() {
        let horror = AppInformationSuggestionSlot.ageRating(.horror)
        #expect(horror.normalized("Infrequent") == "infrequent")
        #expect(horror.normalized("true") == nil)
        #expect(horror.normalized("Yes") == nil)
    }

    @Test func aFeatureTakesYesOrNo() {
        let slot = AppInformationSuggestionSlot.accessibility(.iPhone, .voiceOver)
        #expect(slot.normalized("Yes") == "yes")
        #expect(slot.normalized("false") == "no")
        #expect(slot.normalized("Maybe") == nil)
    }
}
