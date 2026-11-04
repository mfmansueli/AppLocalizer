//
//  AutopilotAppProfileTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What the design brief says the app is, in its own words: the listing's
/// texts as AppLocalizer has them, the plan's languages with their search
/// words, the categories and the icon's colors.
@MainActor
@Suite("Autopilot app profile")
struct AutopilotAppProfileTests {
    @Test func aShortDescriptionIsKeptWhole() {
        #expect(AutopilotAppProfile.opening(of: "  Write a line a day.\n") == "Write a line a day.")
    }

    @Test func aLongDescriptionStopsAfterItsLastWholeSentence() {
        let text = "Lumen keeps a private journal. " + String(repeating: "Every entry stays on your phone. ", count: 30)
        let opening = AutopilotAppProfile.opening(of: text, limit: 120)
        #expect(opening.count <= 120)
        #expect(opening.hasSuffix("phone."))
        #expect(opening.hasPrefix("Lumen keeps a private journal."))
    }

    @Test func withoutASentenceEndItStopsAtAWord() {
        let text = String(repeating: "calm words ", count: 40)
        let opening = AutopilotAppProfile.opening(of: text, limit: 50)
        #expect(opening.hasSuffix("…"))
        #expect(!opening.dropLast().hasSuffix(" "))
        #expect(opening.count <= 51)
    }

    @Test func keywordsAreSplitTrimmedAndKeptOnce() {
        #expect(AutopilotAppProfile.keywords("diary, mood,,Diary ,self care") == ["diary", "mood", "self care"])
        #expect(AutopilotAppProfile.keywords("日記、気分，感謝") == ["日記", "気分", "感謝"])
        #expect(AutopilotAppProfile.keywords("  ").isEmpty)
    }

    /// Lumen's listing with the German subtitle edited: the queued text
    /// counts, the primary comes first, and a language the page doesn't
    /// have is left out.
    @Test func theProfileComesFromTheListingAsAppLocalizerHasIt() throws {
        let profile = AutopilotAppProfile(
            listing: StorePageSampleData.listing, locales: ["de-DE", "en-US", "ja", "xx"],
            categories: ["Lifestyle", "Health & Fitness"], palette: IconPalette(light: "#7C86FF", dark: "#3A2FB8")
        )
        #expect(profile.name == "Lumen: Daily Journal")
        #expect(profile.subtitle == "Private notes, gentle prompts")
        #expect(profile.promotionalText.hasPrefix("New: weekly reflections"))
        #expect(!profile.description.isEmpty)
        #expect(profile.description.count <= AutopilotAppProfile.descriptionLimit)
        #expect(profile.languages.map(\.locale) == ["en-US", "de-DE", "ja"])
        let german = try #require(profile.languages.first { $0.locale == "de-DE" })
        #expect(german.subtitle == "Private Notizen, sanfte Impulse")
        #expect(profile.languages[0].keywords.first == "diary")
        #expect(profile.iconColors == ["#7C86FF", "#3A2FB8"])
        #expect(profile.categories == ["Lifestyle", "Health & Fitness"])
    }

    @Test func theBriefLeavesOutWhatIsEmptyAndSaysHowToUseIt() {
        let profile = AutopilotAppProfile(
            name: "Alba", subtitle: "", categories: [], promotionalText: "", description: "",
            languages: [AutopilotAppProfile.Language(locale: "en-US", name: "Alba", subtitle: "", keywords: ["quotes"])], iconColors: []
        )
        let json = profile.mcpJSON
        #expect(json["name"] == "Alba")
        #expect(json["subtitle"] == nil)
        #expect(json["categories"] == nil)
        #expect(json["description"] == nil)
        #expect(json["iconColors"] == nil)
        #expect(json["languages"] == [["locale": "en-US", "name": "Alba", "keywords": ["quotes"]]])
        let useIt = json["useIt"]?.stringValue ?? ""
        #expect(useIt.contains("not for any app in its categories"))
        #expect(useIt.contains("rationale"))
        #expect(profile.searchWordsJSON(for: ["de-DE"]) == [])
    }
}
