//
//  NewLanguagesDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// The new-language DEBUG scenes resolve, don't clash with the other
/// boards' ids, and their canned data is the design's.
@MainActor
@Suite("NewLanguagesDebugScenes")
struct NewLanguagesDebugScenesTests {
    @Test(arguments: NewLanguagesDebugScenes.ids)
    func everySceneResolves(_ id: String) {
        #expect(NewLanguagesDebugScenes.view(for: id) != nil)
        OverviewSectionView.debugRequestsSuggestEverything = false
    }

    @Test func idsDontClashWithTheOtherBoards() {
        let others = SuggestionsDebugScenes.ids + AssistDebugScenes.ids + EverythingDebugScenes.ids + ReviewPushDebugScenes.ids
        #expect(Set(NewLanguagesDebugScenes.ids).isDisjoint(with: others))
    }

    @Test func claudeCodeDraftedEachNewPage() throws {
        let store = NewLanguagesDebugData.store()
        for locale in NewLanguagesDebugData.languages {
            let drafts = store.open(for: DebugFixtures.AppID.lumen, scope: .storePage(locale))
            #expect(drafts.count == 6)
            // Every draft fits its field's limit.
            for draft in drafts {
                let field = try #require(ListingField(rawValue: draft.target.field))
                #expect(ListingFieldValidator.validate(draft.value, for: field) == .valid, "\(locale.code) \(field.rawValue)")
            }
        }
    }

    @Test func polishIsOnePageWithEightFields() throws {
        let creations = ReviewCreation.group(NewLanguagesDebugData.polishChanges())
        let polish = try #require(creations.first)
        #expect(creations.count == 1)
        #expect(polish.title == "Create the Polish page")
        #expect(polish.fields.map(\.title) == [
            "Name", "Subtitle", "Promotional Text", "Description", "Keywords", "What’s New", "Support URL", "Marketing URL",
        ])
        #expect(polish.fields.last?.source == .builtInSuggestion)
    }
}
#endif
